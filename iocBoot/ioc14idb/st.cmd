# $Id: st.cmd,v 1.3 2008/05/09 17:27:38 epics Exp epics $
#
# $Log: st.cmd,v $
# Revision 1.3  2008/05/09 17:27:38  epics
# Broke up ADDR_LIST line. It was too long. RH
# Added Keithley 2701 support
#
#system clock rate changed to 120- IK 9-25-08
#added support for MSShutterMono 9-25-08
# speed for OMS VME58 card changed to 60Hz  9-25-08
#


sysClkRateSet 240

##< ../nfsCommands

hostAdd "id14b4","164.54.161.158"
nfsAuthUnixSet "id14b4", 615,100,0
nfsMount("id14b4","/home/useridb", "home/useridb")

< ../nfsCommands

< cdCommands

putenv("EPICS_CA_ADDR_LIST=164.54.161.117 164.54.161.76 164.54.161.130")
putenv("EPICS_DB_INCLUDE_PATH", "$(ADCORE)/db:$(QUADEM)/db")
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
< ip330.cmd

# OMS VME58 driver setup parameters: 
#     (1)cards, (2)base address(short, 4k boundary), 
#     (3)interrupt vector (0=disable or  64 - 255), (4)interrupt level (1 - 6),
#     (5)motor task polling rate (min=1Hz,max=60Hz)
oms58Setup(5, 0x4000, 190, 5, 60)

# Joerger VSC setup parameters: 
#     (1)cards, (2)base address(extt, 256-byte boundary), 
#     (3)interrupt vector (0=disable or  64 - 255)
VSCSetup (1, 0xB0000000, 200)
#dbLoadRecords("$(VME)/vmeApp/Db/Jscaler.db","C=0,P=14IDB:,S=sclS1,desc=Timer1")
dbLoadRecords("$(STD)/stdApp/Db/scaler.db","C=0,P=14IDB:,S=sclS1,OUT=#C0 S0 @,FREQ=1e7,DTYP=Joerger VSC8/16")

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)
dvx2502Config(1, 0xc000, 0x100000, 0xd0)
dvx_setIrqLevel(1)
 
# dvx_program(card, board, channel_mask, dma_size, gain)
# Note: we don't have external cards, so we are just using 1 channel from
# each of 8 "ports"
dvx_program(0, 0, 1, 64, 0)
dvx_program(0, 1, 1, 64, 0)
dvx_program(0, 2, 1, 128, 0)
dvx_program(0, 3, 1, 128, 0)
dvx_program(0, 4, 1, 8, 0)
dvx_program(0, 5, 1, 8, 0)
dvx_program(0, 6, 1, 8, 0)
dvx_program(0, 7, 1, 8, 0)

# Configure Acromag AVME 944X Binary I/O (ncards, a16base, intvecbase)
devAvme9440Config(1,0xA000,220)
dbLoadTemplate "14IDB.Binary.template"

#configure Acromag AVME 921X
avme9210Config(1, 8, 0x3000)
dbLoadTemplate "14IDB.DAC.template"

# This changes the scan rate from the default value of 184 kHz to 3.6864 kHz
dvx_SetScanRate(0,0xFC18)
dbLoadTemplate "14IDB.ADC.template"
 
#dbLoadRecords("$(CARS)/CARSApp/Db/scan.db","P=14IDB:,MAXPTS1=2000,MAXPTS2=2000,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")
dbLoadRecords("$(SSCAN)/sscanApp/Db/standardScans.db","P=14IDB:,MAXPTS1=4000,MAXPTS2=2000,MAXPTS3=1000,MAXPTS4=10,MAXPTSH=2000")
dbLoadRecords("$(SSCAN)/sscanApp/Db/saveData.db","P=14IDB:")
dbLoadTemplate "scanParms.template"

# APS Optimization PV's
dbLoadRecords("$(CARS)/CARSApp/Db/APS_Optimize_PV.db","P=14IDB:")

# Combined motion for huber slits
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDB:,SLIT=Huber1V,mXp=m10,mXn=m9")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDB:,SLIT=Huber1H,mXp=m12,mXn=m11")

# Keithley 2701
dbLoadRecords("$(SSCAN)/sscanApp/Db/scan.db","P=14Keithley1:,MAXPTS1=2000,MAXPTS2=2000,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")
dbLoadRecords("$(CALC)/calcApp/Db/userStringCalcs10.db","P=14Keithley1:")
dbLoadRecords("$(CALC)/calcApp/Db/userTransforms10.db","P=14Keithley1:")
dbLoadRecords("$(STD)/stdApp/Db/misc.db","P=14Keithley1:")

######
#deleted quadem IK
######
##Hekstra Setup
# ESP300Setup(max number of controllers, poll rate)
# ESP300Config(card, name, gpib address)
##ESP300Setup(1, 10)
##ESP300Config(0, "serial5", 0)
#drvESP300debug=4
#dbLoadTemplate "14IDB.ESP300.template"
###Hekstra Setup

dbLoadRecords("$(CARS)/CARSApp/Db/vme14IDB.db")
dbLoadRecords("$(CARS)/CARSApp/Db/xiaShutter8.db","P=14IDB:,PHI=m16,OMEGA=m24")
#dbLoadRecords("$(CARS)/CARSApp/Db/MSShutterMono.db","P=14IDB:")
dbLoadRecords("$(CARS)/CARSApp/Db/MS7023Shutter.db","P=14IDB:")

dbLoadRecords("$(CARS)/CARSApp/Db/Backlight.db","P=14IDB:, W=Dliepcr1, D=1, C=8")

dbLoadRecords("$(CARS)/CARSApp/Db/Station_Search.db","N=PA:14ID:,S=B,B=B1Bo, R=6,P=14IDB:,DESC='STATION SEARCHED'")

dbLoadRecords("$(CALC)/calcApp/Db/userAve10.db","P=14IDB:")
#dbLoadRecords("$(CALC)/calcApp/Db/userTransforms10.db","P=14IDB:")
dbLoadRecords("$(CALC)/calcApp/Db/transforms10.db","P=14IDB:,N=1")

dbLoadRecords("$(CARS)/CARSApp/Db/T2_encoders.db","P=14IDB:")

# Multichannel analyzer stuff
# AIMConfig(mpfServer, card, ethernet_address, port, maxChans, 
#           maxSignals, maxSequences, ethernetDevice, queueSize)
AIMConfig("AIM/1", 0xC49, 1, 2048, 1, 1, "fei0")
dbLoadRecords("$(MCA)/mcaApp/Db/mca.db", "P=14IDB:,M=aim_adc1,DTYP=asynMCA,INP=@asyn(AIM/1 0),NCHAN=2048")

icbConfig("icb/1", 0xC49, 1, 0)
dbLoadRecords("$(MCA)/mcaApp/Db/icb_adc.db", "P=14IDB:,ADC=adc1,PORT=icb/1")

# Setup data collection PV's for kbscan and remote access.
dbLoadRecords("$(CARS)/CARSApp/Db/data_collection.db","P=14IDB:")

# Monitor and control millisecond shutter
#dbLoadRecords("CARSApp/Db/14msShutter.db","P=14IDB:",top)

# GoTo buttons
dbLoadRecords("$(CARS)/CARSApp/Db/FastShutter.db","P=14IDB:,Q=FS,M1=m1,M2=m2,M3=fpga_hscd")
dbLoadRecords("$(CARS)/CARSApp/Db/FastShutter.db","P=14IDB:,Q=FS2,M1=m1,M2=m2,M3=fpga_hscd")
dbLoadRecords("$(CARS)/CARSApp/Db/XYZ.db","P=14IDB:,Q=XYZ,M1=m152,M2=m153,M3=m150")
#dbLoadRecords("$(CARS)/CARSApp/Db/SavedPositions4.db","P=14IDB:,Q=DetXY,M1=m33,M2=m34,M3=m3,M4=ESP300Z")
dbLoadRecords("$(CARS)/CARSApp/Db/DetXY.db","P=14IDB:,Q=DetXY,M1=m33,M2=m34,M3=m3,M4=m150")

dbLoadRecords("$(CARS)/CARSApp/Db/beamCheck.db","P=14IDB:")
dbLoadRecords("$(CARS)/CARSApp/Db/14IDB_table_angle.db","P=14IDB:")

dbLoadRecords("$(CARS)/CARSApp/Db/14IDB_table_positions.db","P=14IDB:")
dbLoadRecords("$(CARS)/CARSApp/Db/14IDB_soft_limits.db","P=14IDB:")

# IDB Channel Cut
dbLoadRecords("$(CARS)/CARSApp/Db/IDB_Channel_Cut.db","P=14IDB:,M1=m151,X=m152,Y=m153,Z=150")

dbLoadRecords("$(CARS)/CARSApp/Db/psLaserShutter.db","P=14IDB:")
dbLoadRecords("$(CARS)/CARSApp/Db/SaveSamplePositions.db","P=14IDB:,Q=SP,M1=m152,M2=m153,M3=m150")
dbLoadRecords("$(CARS)/CARSApp/Db/LaserPower.db","P=14IDB:")

#add components M6 VALCO pump and V10 VALCO 10 position valve - IK

dbLoadRecords("$(CARS)/CARSApp/Db/M6VALCOpump.db","P=14IDB:,DEVICE=M6,PORT=serial3")
dbLoadRecords("$(CARS)/CARSApp/Db/VALCOvalve.db","P=14IDB:,DEVICE=V10,PORT=serial13")
dbLoadRecords("$(CARS)/CARSApp/Db/Berek.db","P=14IDB:,DEVICE=BEREK,DESC='BEREK'")

# Move Laser Motors

dbLoadRecords("$(CARS)/CARSApp/Db/LaserMotorsSeq.db","P=14IDB:,P1=14IDLL:, P2=14IDC:")


# IDB Energy Dispersion Goniostat
dbLoadRecords("$(CARS)/CARSApp/Db/Energy_Dispersion.db","P=14IDB:, M=m12")

dbLoadRecords("$(STD)/stdApp/Db/all_com_28.db","P=14IDB:")
dbLoadRecords("$(CALC)/calcApp/Db/userStringSeqs10.db","P=14IDB:")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM1")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM2")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM3")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM4")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM5")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM6")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM7")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM8")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM9")
#dbLoadRecords("$(STD)/stdApp/Db/softMotor.db","P=14IDB:,SM=SM10")

dbLoadRecords("$(CARS)/CARSApp/Db/Filter_insert.db","P=14IDB:,S=Filter_insert")
dbLoadRecords("$(CARS)/CARSApp/Db/Filter_remove.db","P=14IDB:,S=Filter_remove")

# IOC stats
epicsEnvSet("LOCATION","14IDB control room")
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminVxWorks.db","IOC=14IDB")
dbLoadTemplate "iocEnvVar.substitutions"

dbLoadRecords("$(CARS)/CARSApp/Db/Pause_scans.db","P=14IDB:")

dbLoadTemplate "14IDB.Steppers.template"
dbLoadTemplate "14IDB.DAC.template"
dbLoadTemplate "14IDB.ADC.template"
#dbLoadTemplate "templates/14IDB.Binary.template"
dbLoadTemplate "14IDB.Table.template"
dbLoadTemplate "14IDB.pseudoMotor.template"

#< alio.cmd

# Pseudo vertical and horizontal motion of the ALIO
#dbLoadRecords("$(CARS)/CARSApp/Db/SampleYZ_IDB.db","P=14IDB:,X=m152,Y=m153,PHI=m151")

# Load Bunch Clock
# Removed on 10/29/11 RH, TG
#BunchClkGenConfigure( 0, 0x3480)
##dbLoadRecords("$(VME)/vmeApp/Db/BunchClkGen.db","P=14IDB:")
#dbLoadRecords("$(VME)/vmeApp/Db/BunchClkGenA.db", "UNIT=14IDB:")

#iocLogDisable=0

<../save_restore.cmd

save_restoreSet_status_prefix("14IDB:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14IDB:")

# Access security
# This was needed to enable caPutLog
#asSetFilename("../access_security.acf")

##
# IOC INIT
#

iocInit

##############save_restoreSet_FilePermissions(0666)
create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# Start scaler
dbpf "14IDB:sclS1.TP","0.1"
dbpf "14IDB:sclS1.PROC","1"

# Setup detectors in scan record
dbpf "14IDB:scan1.D02PV","14IDB:sclS1.S2"
dbpf "14IDB:scan1.D03PV","14IDB:sclS1.S3"
dbpf "14IDB:scan1.D04PV","14IDB:sclS1.S4"
dbpf "14IDB:scan1.D05PV","14IDB:sclS1.S5"
dbpf "14IDB:scan1.D06PV","14IDB:sclS1.S6"
dbpf "14IDB:scan1.D07PV","14IDB:sclS1.S7"
dbpf "14IDB:scan1.D08PV","14IDB:sclS1.S8"
dbpf "14IDB:scan1.D09PV","14IDB:sclS1.S9"
dbpf "14IDB:scan1.D10PV","14IDB:sclS1.S10"
dbpf "14IDB:scan1.D11PV","14IDB:sclS1.S11"
dbpf "14IDB:scan1.D12PV","14IDB:sclS1.S12"
dbpf "14IDB:scan1.D13PV","14IDB:sclS1.S13"
dbpf "14IDB:scan1.D14PV","14IDB:sclS1.S14"
dbpf "14IDB:scan1.D15PV","14IDB:sclS1.S15"
dbpf "14IDB:scan1.D16PV","14IDB:sclS1.S16"
 
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
saveData_Init("saveData.req", "P=14IDB:")
 
# Reduce delay after using scaler from 10 s to 1 s
scaler_wait_time=1
 
seq &Keithley2kDMM, "P=14Keithley1:, Dmm=DMM1, channels=22, model=2700, stack=10000"
#seq &gentecDuo, "P=14IDB:"
seq &sigmaMeter, "P=14IDB:"
seq &keithley6485st, "P=14IDB:,R=Keithley1:"
seq &keithley6485st, "P=14IDB:,R=Keithley2:"
#seq &MSShutterMono, "P=14IDB:, M1=m16, D=DAC1_1"
#seq &MS7023Shutter, "P=14IDB:, M1=m16"
seq &beamCheck
seq &fpga, "P=14IDB:, S=serial18, S2=serial20, F=fpga"
seq &dliEpcr, "P=14IDB:, D=Dliepcr1, AP=serial19, USER=admin, PWD=admin, M=LPC2"
seq &laserPower, "P=14IDB:"
seq &laserShutter, "P=14IDB:"
###seq &getFillPat, "unit=S14IDB:"
seq &M6VALCOpump, "P=14IDB:, D=M6:"

str2=malloc((6*64)+1)
#strcpy(str2,"P=14IDB:,D=alio1,PORT=pmacAliog,PHI=2,X=3,Y=4,Z=1,AIR=M115,AIRT=P907,XYDAC=P810,PHS=P1011,")
#strcat(str2,"PHPLC=2,PPLC=10,PS=P910,HPLC=11,HS=P920,APC=0,APCS=1,AMIPP=500,ACIPP=500,I=14IDB:Is,E=14IDB:Exphi")
###strcpy(str2,"P=14IDB:,D=alio1,PORT=pmacAliog,PHI=2,X=3,Y=4,Z=1,AIR=M115,AIRT=P907,")
###strcat(str2,"XYDAC=P810,PHS=P1011,PHPLC=2,PPLC=10,PS=P910,HPLC=11,HS=P920,APC=0,")
###strcat(str2,"AE=P20,APCS=1,AMIPP=500,ACIPP=500,P250=P250,P251=P251,P252=P252,P255=P255,P256=P256,P257=P257,")
###strcat(str2,"P258=P258,P259=P259,P260=P260,P261=P261,P262=P262,P263=P263,P264=P264,I=14IDB:Is,E=14IDB:Exphi")
###seq &aliogFSMs_BioCARS, str2

seq &quadEM_SNL, "P=14IDB:, R=QE1_TS:,NUMCHANNELS=2048" 

dbpf "14IDB:userStringSeqEnable.VAL","1"
dbpf "14IDB:userAveEnable.VAL","1"
#dbpf "14IDB:EM1ConversionTime.VAL",".00062"
#dbpf "14IDB:EM1Read.SCAN","9"
dbpf "14IDB:Keithley1:Inverse.VAL","-1"
#drvESP300debug=0
