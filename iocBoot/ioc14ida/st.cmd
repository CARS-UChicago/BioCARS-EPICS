# $Id: ioc14ida.cmd,v 1.8 2007/11/26 19:13:16 epics Exp epics $
#

##
# install nfs
#
< ../nfsCommands_01182017

< cdCommands

#putenv("EPICS_CA_ADDR_LIST=192.168.2.17 164.54.161.117")

cd topbin

ld(0,0,"CARS.munch")
cd startup

# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in this build from CARS
dbLoadDatabase("$(CARS)/dbd/iocCARSVX.dbd")
iocCARSVX_registerRecordDeviceDriver(pdbbase)

errlogInit(50000)

< industryPack.cmd
< serial.cmd

# OMS VME58 driver setup parameters:
#     (1)cards, (2)base address(short, 4k boundary),
#     (3)interrupt vector (0=disable or  64 - 255), (4)interrupt level (1 - 6),
#     (5)motor task polling rate (min=1Hz,max=60Hz)
oms58Setup(2, 0x4000, 190, 5, 10)
dbLoadTemplate "14IDA.Steppers.template"

# Joerger VSC setup parameters:
#     (1)cards, (2)base address(ext, 256-byte boundary),
#     (3)interrupt vector (0=disable or  64 - 255)
# Can't use D000000 on PowerPC, change to B0000000
#dbLoadRecords("$(VME)/vmeApp/Db/Jscaler.db","C=0,P=14IDA:,S=sclS1,desc=Timer1")
dbLoadRecords("$(STD)/stdApp/Db/scaler.db","C=0,P=14IDA:,S=sclS1,OUT=#C0 S0 @,FREQ=1e7,DTYP=Joerger VSC8/16")
VSCSetup (1, 0xB0000000, 200)

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)
dvx2502Config(1, 0xc000, 0x100000, 0xd0)
dvx_setIrqLevel(1)
dbLoadTemplate "14IDA.ADC.template"
dbLoadRecords("$(CARS)/CARSApp/Db/IDApresTemp.db", "P=14IDA")

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

#===============================================================
# ID-EPS Ruan
dbLoadRecords("$(CARS)/CARSApp/Db/14ID-EPS_2K10_login.db","P=14IDA:")
dbLoadRecords("$(CARS)/CARSApp/Db/14ID-EPS_2K10_hc.db","P=14IDA:")
dbLoadRecords("$(CARS)/CARSApp/Db/14ID-EPS_2K10_WF-TC_R-VAL.db","P=14IDA:")

dbLoadTemplate "14ID-EPS_2K10_buttons.template"
dbLoadTemplate "14ID-EPS_2K10_1d-INP.template"
dbLoadTemplate "14ID-EPS_2K10_3d-INP.template"
#dbLoadTemplate "14ID-EPS_2K10_vlvOP.template"

# Test direct valve control
dbLoadRecords("$(CARS)/CARSApp/Db/14ID-EPS_valve2.db","P=14IDA:")

#dbLoadTemplate "TEST_14ID-EPS_INP.template"

#=================================================================

dbLoadRecords("$(CARS)/CARSApp/Db/undPseudo.db","P=14IDA:,U=U27,xx=14us")
dbLoadRecords("$(CARS)/CARSApp/Db/undPseudo.db","P=14IDA:,U=U23,xx=14ds")

# GoTo buttons for Undulators
dbLoadRecords("$(CARS)/CARSApp/Db/UndPos.db","P=14IDA:,Q=Und,M1=U23Gap,M2=U27Gap")

# Combined motion for white slits
dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDA:,SLIT=Slit1V,mXp=m1,mXn=m2")
dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDA:,SLIT=Slit1H,mXp=m4,mXn=m3")

# Combined motion for mirror
#dbLoadRecords("$(CARS)/CARSApp/Db/mirror.db","P=14IDA:,MIR=mir1,Y1=m17, Y2=m18, Y3=m19, X1=m20, X2=m21")
dbLoadTemplate "14IDA.pseudoMotor.template"

# Remote Shutter
#dbLoadRecords("$(CARS)/CARSApp/Db/remote_shutter.db","P=14IDA:,N=1,B=1,Q=FE:14:ID:FEshutter")
#dbLoadRecords "$(CARS)/CARSApp/Db/remote_shutter_station.db","P=14IDA:,N=1,EPS=14IDA:eps_bi315,ShutterStatus="
#dbLoadRecords "$(CARS)/CARSApp/Db/remote_shutter_station.db","P=14IDA:,N=1,EPS=14IDA:eps_bi94,ShutterStatus=14IDA:eps_bi113"
## IK comment out 14IDA.RemoteShutter.template 5/2011
#dbLoadTemplate "14IDA.RemoteShutter.template"
dbLoadTemplate "14IDA.RemoteShutterModIDB.template"

# Setup pzt for mono and mirror
###########comm out pzts on init sets pzt to 0 IK ###########################
#dbLoadRecords("$(CARS)/CARSApp/Db/pzt.db","P=14IDA:, C=3, D=1, E=1, PM=pm1")
#dbLoadRecords("$(CARS)/CARSApp/Db/pzt.db","P=14IDA:, C=4, D=1, E=2, PM=pm2")

# NL, for kohzu mono 
dbLoadRecords("$(CARS)/CARSApp/Db/kohzuSeq.db","P=14IDA:,M_Z=m11,M_THETA=m9,M_Y=m10,GEOM=1,yOffHi=10,yOffLo=-1")
dbLoadRecords("$(CARS)/CARSApp/Db/allStopIDA.db","P=14IDA:")

# Heidenhain encoder for mono theta
#dbLoadRecords("$(IP)/ipApp/Db/heidND261.db", "P=14IDA:, PORT=serial9")

dbLoadTemplate "14IDA.mono_pid.template"

dbLoadTemplate "14IDA.vmirror_pid.template"
dbLoadRecords("$(CALC)/calcApp/Db/userTransforms10.db","P=14IDA:")
dbLoadRecords("$(CARS)/CARSApp/Db/IDApresTemp.db", "P=14IDA:")
#dbLoadRecords("$(CARS)/CARSApp/Db/HeatLoadShutter.db","P=14IDA:,Q=HLS,M1=m5")
dbLoadRecords("$(CARS)/CARSApp/Db/HeatLoadShutter_IK.db","P=14IDA:,P1=14IDB:,Q=HLS,M1=m5, M2=fpga_DRV:hlcnd")
                                                                                     
# Allen-Bradley 6008 scanner
# EPICS driver document: http://www.aps.anl.gov/eics/modules/bus/allenBradley/R2-1/allenBradley
# abConfigBaud(link, rate); rate=0: 57.6kbps, rate=1: 115.2 kbps
abConfigNlinks 1
abConfigVme 0,0xc00000,0x60,5
abConfigAuto
#abConfigBaud(1, 1)

# IOC stats
epicsEnvSet("LOCATION","14IDA Outside FOE")
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminVxWorks.db","IOC=14IDA")
dbLoadTemplate "iocEnvVar.substitutions"


< ../save_restore.cmd
save_restoreSet_status_prefix("14IDA:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14IDA:")

##
# IOC INIT
#

iocInit

#save_restoreSet_FilePermissions(0666)
create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# Start scaler
dbpf "14IDA:sclS1.TP","0.1"
dbpf "14IDA:sclS1.PROC","1"

# Reduce delay after using scaler from 10 s to 1 s
scaler_wait_time=1

# NL, for kohzu mono
seq &kohzuCtl, "P=14IDA:"

#seq &EPS_14ID
seq &EPS_vlv, "P=14IDA:"

dbpf "14IDA:KohzuModeBO.VAL","Auto"
dbpf "14IDA:userTranEnable.VAL","1"

