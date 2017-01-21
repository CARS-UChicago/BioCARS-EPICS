# $Id: ioc14ida.cmd,v 1.4 2006/08/13 03:28:42 epics Exp epics $
#

##
# install nfs
#
< nfs_2100.cmd

< /home/epics/synApps5-1beta2/CARS/iocBoot/ioc14ida/cdCommands

# NL  IDA: 1; IDB: 2; BMA: 3; BMC: 4
routeAdd "192.168.1.0", "192.168.1.65"
routeAdd "0","192.168.1.17"
routeAdd "164.54.0.0","192.168.1.65"
putenv("EPICS_CA_ADDR_LIST=192.168.2.17 164.54.161.117")

cd topbin
ld < CARSApp.munch
cd startup


# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in this build from CARS
dbLoadDatabase("$(CARS)/dbd/CARSVX.dbd")
CARSVX_registerRecordDeviceDriver(pdbbase)

errlogInit(50000)

< industryPack.cmd
< serial.cmd

# OMS VME58 driver setup parameters:
#     (1)cards, (2)axis per card, (3)base address(short, 4k boundary),
#     (4)interrupt vector (0=disable or  64 - 255), (5)interrupt level (1 - 6),
#     (6)motor task polling rate (min=1Hz,max=60Hz)
oms58Setup(4, 8, 0x4000, 190, 5, 10)

# for motor PVs
dbLoadTemplate "14IDA.Steppers.template"

# Joerger VSC setup parameters:
#     (1)cards, (2)base address(ext, 256-byte boundary),
#     (3)interrupt vector (0=disable or  64 - 255)
# Can't use D000000 on PowerPC, change to B0000000
dbLoadRecords("$(VME)/vmeApp/Db/Jscaler.db","C=0,P=14IDA:,S=sclS1,desc=Timer1")
VSCSetup (1, 0xB0000000, 200)

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)
dvx2502Config(1, 0xc000, 0x100000, 0xd0)
dvx_setIrqLevel(1)

# set up the Allen-Bradley 6008 scanner
#abConfigNlinks 1
#abConfigVme 0,0xc00000,0x60,5
#abConfigAuto

# dvx_program(card, board, channel_mask, dma_size, gain)
# Note: we don't have external cards, so we are just using 1 channel from
# each of 8 "ports"
dvx_program(0, 0, 1, 8, 0) 
dvx_program(0, 1, 1, 8, 0) 
dvx_program(0, 2, 1, 8, 0) 
dvx_program(0, 3, 1, 8, 0) 
dvx_program(0, 4, 1, 8, 0) 
dvx_program(0, 5, 1, 8, 0) 
dvx_program(0, 6, 1, 8, 0) 
dvx_program(0, 7, 1, 8, 0) 

# This changes the scan rate from the default value of 184 kHz to 3.6864 kHz
dvx_SetScanRate(0,0xFC18)


# Configure Acromag AVME 9440 Binary I/O (ncards, a16base, intvecbase)
devAvme9440Config(1,0xA000,220)

avme9210Config(1, 8, 0x3000)
dbLoadTemplate "14IDA.DAC.template"

# ID-EPS Ruan
dbLoadTemplate "14ID-EPS_2K6_buttons.template"
dbLoadTemplate "14ID-EPS_2K6_input-A.template"
dbLoadTemplate "14ID-EPS_2K6_input-B.template"
dbLoadTemplate "14ID-EPS_2K6_tgt-sel.template"
dbLoadTemplate "14ID-EPS_2K6_valHunt.template"
dbLoadRecords("$(CARS)/biocarsApp/Db/14ID-EPS_2K6_tgt-identify.db", "P=14IDA:")
dbLoadRecords("$(CARS)/biocarsApp/Db/14ID-EPS_2K6_analog-io.db", "P=14IDA:")
#dbLoadRecords("$(CARS)/biocarsApp/Db/14ID-EPS_2K6_long-io.db", "P=14IDA:")

# Scan Record
#dbLoadRecords("$(CARS)/biocarsApp/Db/scan.db","P=14IDA:,MAXPTS1=2000,MAXPTS2=200,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")
#dbLoadTemplate "scanParms.template"

# Combined motion for white slits
dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDA:,SLIT=Slit1V,mXp=m1,mXn=m2")
dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDA:,SLIT=Slit1H,mXp=m4,mXn=m3")

# Combined motion for mirror
dbLoadRecords("$(CARS)/biocarsApp/Db/mirror.db","P=14IDA:,MIR=mir1,Y1=m17, Y2=m18, Y3=m19, X1=m20, X2=m21")
dbLoadTemplate "14IDA.pseudoMotor.template"

# Remote Shutter
dbLoadRecords("$(CARS)/biocarsApp/Db/remote_shutter.db","P=14IDA:,N=1,B=1,Q=FE:14:ID:FEshutter")

# NL, for kohzu mono 
dbLoadRecords("$(CARS)/biocarsApp/Db/kohzuSeq.db","P=14IDA:,M_Z=m11,M_THETA=m9,M_Y=m10,GEOM=1,yOffHi=10,yOffLo=-1")
dbLoadRecords("$(CARS)/biocarsApp/Db/allStopIDA.db","P=14IDA:")
                                                                                                                
# Allen-Bradley 6008 scanner
# EPICS driver document: http://www.aps.anl.gov/eics/modules/bus/allenBradley/R2-1/allenBradley
# abConfigBaud(link, rate); rate=0: 57.6kbps, rate=1: 115.2 kbps
abConfigNlinks 1
abConfigVme 0,0xc00000,0x60,5
abConfigAuto
#abConfigBaud(1, 1)


< ../save_restore.cmd
save_restoreSet_status_prefix("14IDA:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14IDA:")

##
# IOC INIT
#

iocInit

create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# Start scaler
dbpf "14IDA:sclS1.TP","0.1"
dbpf "14IDA:sclS1.PROC","1"

### Start the saveData task.
# saveData_MessagePolicy
# 0: wait forever for space in message queue, then send message
# 1: send message only if queue is not full
# 2: send message only if queue is not full and specified time has passed (SetCptWait()
#    sets this time.)
# 3: if specified time has passed, wait for space in queue, then send message
# else: don't send message
#debug_saveData = 2
saveData_MessagePolicy = 2
saveData_SetCptWait_ms(100)
saveData_Init("saveDataExtraPVs.req", "P=14IDA:")

# Reduce delay after using scaler from 10 s to 1 s
scaler_wait_time=1

# NL, for kohzu mono
seq &kohzuCtl, "P=14IDA:"

ld < mirror.o
seq &mirror, "P=14IDA:, mir = mir1, Y1=m17, Y2=m18, Y3=m19,  GEOM=1"
