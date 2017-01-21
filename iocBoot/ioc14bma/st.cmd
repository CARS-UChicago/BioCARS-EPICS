# $Id: st.cmd,v 1.1 2008/05/08 19:22:52 epics Exp epics $
#
# Sep 28, 2005


##
# install nfs
#
< ../nfsCommands

< cdCommands



cd topbin

load("CARS.munch")
cd startup


# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in this build from CARS
dbLoadDatabase("$(CARS)/dbd/iocCARSVX.dbd")
iocCARSVX_registerRecordDeviceDriver(pdbbase)

errlogInit(50000)

< industryPack.cmd
< serial.cmd

#devOms58debug = 10
#drvOms58debug = 10
#devOms58debug = 4
#drvOms58debug = 4
# OMS VME58 driver setup parameters:
#     (1)cards, (2)base address(short, 4k boundary),
#     (3)interrupt vector (0=disable or  64 - 255), (4)interrupt level (1 - 6),
#     (5)motor task polling rate (min=1Hz,max=60Hz)
oms58Setup(6, 0x4000, 190, 5, 10)

# Joerger VSC setup parameters:
#     (1)cards, (2)base address(ext, 256-byte boundary),
#     (3)interrupt vector (0=disable or  64 - 255)
# Can't use D000000 on PowerPC, change to B0000000
#dbLoadRecords("$(VME)/vmeApp/Db/Jscaler.db","C=0,P=14BMA:,S=sclS1,desc=Timer1")
dbLoadRecords("$(STD)/stdApp/Db/scaler.db","C=0,P=14BMA:,S=sclS1,OUT=#C0 S0 @,FREQ=1e7,DTYP=Joerger VSC8/16")
VSCSetup (1, 0xB0000000, 200)

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)

dvx2502Config(1, 0xc000, 0x100000, 0xd0)
dvx_setIrqLevel(1)

# Set up the Allen-Bradley 6008 scanner
abConfigNlinks 1
abConfigVme 0,0xc00000,0x60,5
abConfigAuto


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

dbLoadTemplate "14BMA.ADC.template"
dbLoadTemplate "14BMA.Binary.template"
dbLoadTemplate "14BMA.DAC.template"
dbLoadTemplate "14BM.EPS.template"
dbLoadTemplate "14BMA.Steppers.template"
dbLoadTemplate "14BMA.Servo.template"
dbLoadTemplate "14BMA.RotarySlit.template"
dbLoadTemplate "14BMA.Mirror.template"
dbLoadTemplate "14BMA.PseudoMotor.template"
#dbLoadTemplate "14BMA.RemoteShutter.template"
# append Modified version for  testing on 2/16/2011
dbLoadTemplate "14BMA.RemoteShutterMod.template"

dbLoadRecords("$(CARS)/CARSApp/Db/BMCMBendDist.db","P=14BMA:",top)
dbLoadRecords("$(CARS)/CARSApp/Db/Chi2.db","P=14BMA:,C=Dmonotilt,D=-26000,E=Dmonotheta1",top)

# IOC stats
epicsEnvSet("LOCATION","14BMA Outside FOE")
## Register all support components

## Load all record instances (VxWorks)
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminVxWorks.db","IOC=14BMA")
dbLoadTemplate "iocEnvVar.substitutions"




< ../save_restore.cmd
save_restoreSet_status_prefix("14BMA:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14BMA:")

##
# IOC INIT
#

iocInit

####save_restoreSet_FilePermissions(0666)
create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# Start scaler
dbpf "14BMA:sclS1.TP","0.1"
dbpf "14BMA:sclS1.PROC","1"

### Start the saveData task.
# saveData_MessagePolicy
# 0: wait forever for space in message queue, then send message
# 1: send message only if queue is not full
# 2: send message only if queue is not full and specified time has passed (SetCptWait()
#    sets this time.)
# 3: if specified time has passed, wait for space in queue, then send message
# else: don't send message
#debug_saveData = 2
#saveData_MessagePolicy = 2
#saveData_SetCptWait_ms(100)
#saveData_Init("saveDataExtraPVs.req", "P=14BMA:")
#saveData_PrintScanInfo("14BMA:scan1")

# Reduce delay after using scaler from 10 s to 1 s
scaler_wait_time=1
