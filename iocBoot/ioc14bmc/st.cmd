# $Id: st.cmd,v 1.1 2008/05/08 16:05:40 epics Exp epics $
#


##
# install nfs
#

hostAdd "bm14c4","164.54.161.156"
nfsAuthUnixSet "bm14c4",616,100,0
nfsMount("bm14c4","/home/userbmc","home/userbmc")
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

#drvESP300debug = 4

< industryPack.cmd
< serial.cmd

# OMS VME58 driver setup parameters:
#     (1)cards, (2)base address(short, 4k boundary),
#     (3)interrupt vector (0=disable or  64 - 255), (4)interrupt level (1 - 6),
#     (5)motor task polling rate (min=1Hz,max=60Hz)
oms58Setup(3, 0x4000, 190, 5, 10)
dbLoadTemplate "14BMC.Steppers.template"

# Joerger VSC setup parameters:
#     (1)cards, (2)base address(ext, 256-byte boundary),
#     (3)interrupt vector (0=disable or  64 - 255)
# Can't use D000000 on PowerPC, change to B0000000
VSCSetup (1, 0xB0000000, 200)
#dbLoadRecords("$(VME)/vmeApp/Db/Jscaler.db","C=0,P=14BMC:,S=sclS1,desc=Timer1")
dbLoadRecords("$(STD)/stdApp/Db/scaler.db","C=0,P=14BMC:,S=sclS1,OUT=#C0 S0 @,FREQ=1e7,DTYP=Joerger VSC8/16")

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)
##IK comment out analogic support because it is not in use and this support produces a unrecognized interrupt 236 error due to it incompatibility vxWorks6.9 (CentOS7)
# will work but produces tons of errors
dvx2502Config(1, 0xc000, 0x100000, 0xd0)
dvx_setIrqLevel(1)

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
dbLoadTemplate "14BMC.ADC.template"

# Configure Acromag AVME 9440 Binary I/O (ncards, a16base, intvecbase)
devAvme9440Config(1,0xA000,220)
dbLoadTemplate "14BMC.Binary.template"
# uncommented for Delay Generator
#dbLoadRecords("$(VME)/vmeApp/Db/Acromag_16IO.db","P=14BMC:,A=B1,C=0")

avme9210Config(1, 8, 0x3000)
dbLoadTemplate "14BMC.DAC.template"

##dbLoadRecords("$(CARS)/CARSApp/Db/scan.db","P=14BMC:,MAXPTS1=2000,MAXPTS2=1000,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")
#dbLoadRecords("$(SSCAN)/sscanApp/Db/scan.db","P=14BMC:,MAXPTS1=2000,MAXPTS2=1000,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")
dbLoadRecords("$(SSCAN)/sscanApp/Db/standardScans.db","P=14BMC:,MAXPTS1=4000,MAXPTS2=2000,MAXPTS3=1000,MAXPTS4=10,MAXPTSH=2000")
dbLoadRecords("$(SSCAN)/sscanApp/Db/saveData.db","P=14BMC:")
dbLoadTemplate "scanParms.template"

# Setup scan record which does not write to a file
dbLoadRecords("$(SSCAN)/sscanApp/Db/scanAux.db","P=14BMC:, S=scan1")



# ESP300Setup(max number of controllers, poll rate)
# ESP300Config(card, name, gpib address)
ESP300Setup(1, 10)
ESP300Config(0, "serial5", 0)
# ESP300Config(0, "serial10", 0)
dbLoadTemplate "14BMC.ESP300.template"

### Allstop, alldone
# This database must agree with the motors you've actually loaded.
# Several versions (e.g., all_com_32.db) are in std/stdApp/Db
dbLoadRecords("$(CARS)/CARSApp/Db/all_com_28.db","P=14BMC:")
dbLoadRecords("$(CARS)/CARSApp/Db/stop_button.db","P=14BMC:")

dbLoadRecords("$(CARS)/CARSApp/Db/vme14BMC.db")

# Setup data collection PV's for kbscan and remote access.
dbLoadRecords("$(CARS)/CARSApp/Db/data_collection.db","P=14BMC:")

# Support for XIA shutter using the 7023 card
#dbLoadRecords("$(CARS)/CARSApp/Db/xiaShutter4.db","P=14BMC:")
#dbLoadRecords("$(CARS)/CARSApp/Db/xiaShutter6.db","P=14BMC:")
dbLoadRecords("$(CARS)/CARSApp/Db/xiaShutter7.db","P=14BMC:")

# Monitor and control millisecond shutter
dbLoadRecords("$(CARS)/CARSApp/Db/14msShutter.db","P=14BMC:")

# Automate sample mounting
dbLoadRecords("$(CARS)/CARSApp/Db/sample_mounting.db","P=14BMC:")

# Disable motors if air or brakes are not on
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=txu,N=1")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=txd,N=1")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=tX,N=1")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=tXa,N=1")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=dyu,N=2")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=dyd,N=3")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=dY,N=2")
dbLoadRecords("$(CARS)/CARSApp/Db/interlock.db","P=14BMC:,M=dYa,N=2")

#Adds a dfanout PV to control detector brakes
dbLoadRecords("$(CARS)/CARSApp/Db/BMC_detector.db","P=14BMC:")
 
# Change soft limits to prevent a collision.
dbLoadRecords("$(CARS)/CARSApp/Db/BMC_soft_limits.db","P=14BMC:")

# adsc detector
dbLoadRecords("$(CARS)/CARSApp/Db/adsc.db", "P=14BMC:,C=ADSC")

# Keithley 2701
dbLoadRecords("$(SSCAN)/sscanApp/Db/scan.db","P=14BMC:,MAXPTS1=2000,MAXPTS2=200,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")
dbLoadRecords("$(CALC)/calcApp/Db/userStringSeqs10.db","P=14BMC:")
dbLoadRecords("$(CALC)/calcApp/Db/userStringCalcs10.db","P=14BMC:")
dbLoadRecords("$(CALC)/calcApp/Db/userTransforms10.db","P=14BMC:")
dbLoadRecords("$(STD)/stdApp/Db/misc.db","P=14BMC:")

# added FlowCell VALCO M6 and V10 10-6-10
 
dbLoadRecords("$(CARS)/CARSApp/Db/M6VALCOpump.db","P=14BMC:,DEVICE=M6,PORT=serial9")
dbLoadRecords("$(CARS)/CARSApp/Db/VALCOvalve.db","P=14BMC:,DEVICE=V10,PORT=serial10")
dbLoadRecords("$(CARS)/CARSApp/Db/VALCOvalve.db","P=14BMC:,DEVICE=V10_1,PORT=serial11")

# Setup support for 4step scans
dbLoadRecords("$(STD)/stdApp/Db/4step.db","P=14BMC:, Q=4step:")

# Save goniometer positions
dbLoadRecords("$(CARS)/CARSApp/Db/XYZ_phi.db","P=14BMC:,Q=XYZ_phi,M1=phi,M2=ESP300X,M3=ESP300Y,M4=ESP300Z")

# IOC stats
epicsEnvSet("LOCATION","14BMC control room")
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminVxWorks.db","IOC=14BMC")
dbLoadTemplate "iocEnvVar.substitutions"




< ../save_restore.cmd
save_restoreSet_status_prefix("14BMC:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14BMC:")


##
# IOC INIT
#

iocInit

save_restoreSet_FilePermissions(0666)
create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# Start scaler
dbpf "14BMC:sclS1.TP","0.1"
dbpf "14BMC:sclS1.PROC","1"

# Setup detectors in scan record
dbpf "14BMC:scan1.D02PV","14BMC:sclS1.S2"
dbpf "14BMC:scan1.D03PV","14BMC:sclS1.S3"
dbpf "14BMC:scan1.D04PV","14BMC:sclS1.S4"
dbpf "14BMC:scan1.D05PV","14BMC:sclS1.S5"
dbpf "14BMC:scan1.D06PV","14BMC:sclS1.S6"
dbpf "14BMC:scan1.D07PV","14BMC:sclS1.S7"
dbpf "14BMC:scan1.D08PV","14BMC:sclS1.S8"
dbpf "14BMC:scan1.D09PV","14BMC:sclS1.S9"
dbpf "14BMC:scan1.D10PV","14BMC:sclS1.S10"
dbpf "14BMC:scan1.D11PV","14BMC:sclS1.S11"
dbpf "14BMC:scan1.D12PV","14BMC:sclS1.S12"
dbpf "14BMC:scan1.D13PV","14BMC:sclS1.S13"
dbpf "14BMC:scan1.D14PV","14BMC:sclS1.S14"
dbpf "14BMC:scan1.D15PV","14BMC:sclS1.S15"
dbpf "14BMC:scan1.D16PV","14BMC:sclS1.S16"

# Make sure brakes for dyu and dyd motors are energized.
dbpf "14BMC:B1Bo1.VAL","1"
dbpf "14BMC:B1Bi2.PROC","1"
dbpf "14BMC:B1Bi3.PROC","1"

# Make sure air is off for txu and txd motors
dbpf "14BMC:B1Bo0.VAL","0"

# Check stop button status and enable record
dbpf "14BMC:B1Bi7.PROC","1"
dbpf "14BMC:stop_button.DISA","0"
 
# Start Mount Sampel SNL
seq &Mount_sample, "P=14BMC:"
 
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
saveData_Init("saveData.req", "P=14BMC:")
#saveData_PrintScanInfo("14BMC:scan1")

# Reduce delay after using scaler from 10 s to 1 s
scaler_wait_time=1

# Remove menu items from SEQ_TYPE
dbpf "14BMC:SEQ_TYPE.FRST",""
dbpf "14BMC:SEQ_TYPE.FVST",""
dbpf "14BMC:SEQ_TYPE.SXST",""
dbpf "14BMC:SEQ_TYPE.SVST",""
dbpf "14BMC:SEQ_TYPE.EIST",""

# Turn detector encoders off.
dbpf "14BMC:dzUseEncoder","1"
dbpf "14BMC:dyuUseEncoder","1"
dbpf "14BMC:dydUseEncoder","1"

#seq &Keithley2kDMM, "P=14BMC:, Dmm=DMM1, channels=22, model=2700, stack=10000"
seq &M6VALCOpump, "P=14BMC:, D=M6:"
