

# $Id: ioc14ida.cmd,v 1.4 2006/08/13 03:28:42 epics Exp epics $
#

##
# install nfs

#


< ../nfsCommands

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
####oms58Setup(3, 0x4000, 190, 5, 10)
oms58Setup(6, 0x4000, 190, 5, 10)
dbLoadTemplate "14IDC.Steppers.template"
dbLoadTemplate "14IDC.Table.template"

# Joerger VSC setup parameters:
#     (1)cards, (2)base address(ext, 256-byte boundary),
#     (3)interrupt vector (0=disable or  64 - 255)
# Can't use D000000 on PowerPC, change to B0000000
#dbLoadRecords("$(VME)/vmeApp/Db/Jscaler.db","C=0,P=14IDC:,S=sclS1,desc=Timer1")
#VSCSetup (1, 0xB0000000, 200)

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)
#dvx2502Config(1, 0xc000, 0x100000, 0xd0)
#dvx_setIrqLevel(1)
#dbLoadTemplate "14IDA.ADC.template"

# dvx_program(card, board, channel_mask, dma_size, gain)
# Note: we don't have external cards, so we are just using 1 channel from
# each of 8 "ports"
#dvx_program(0, 0, 1, 8, 0) 
#dvx_program(0, 1, 1, 8, 0) 
#dvx_program(0, 2, 1, 8, 0) 
#dvx_program(0, 3, 1, 8, 0) 
#dvx_program(0, 4, 1, 8, 0) 
#dvx_program(0, 5, 1, 8, 0) 
#dvx_program(0, 6, 1, 8, 0) 
#dvx_program(0, 7, 1, 8, 0) 

# This changes the scan rate from the default value of 184 kHz to 3.6864 kHz
#dvx_SetScanRate(0,0xFC18)

# Configure Acromag AVME 9440 Binary I/O (ncards, a16base, intvecbase)
#devAvme9440Config(1,0xA000,220)

#avme9210Config(1, 8, 0x3000)
#dbLoadTemplate "14IDA.DAC.template"


# Combined motion for V- mirror
dbLoadRecords("$(CARS)/CARSApp/Db/mirror.db","P=14IDC:,MIR=mir1,Y1=m1, Y2=m2, Y3=m3, X1=m4, X2=m5")
dbLoadRecords("$(CARS)/CARSApp/Db/Hmirror.db","P=14IDC:,MIR=mir2,Y1=m9, Y2=m10, Y3=m11, X1=m12, X2=m13")
dbLoadTemplate "14IDC.pseudoMotor.template"

# Combined motion for pink slits
dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDC:,SLIT=Slit1V,mXp=m17,mXn=m18")
dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDC:,SLIT=Slit1H,mXp=m20,mXn=m19")

# IOC stats
epicsEnvSet("LOCATION","14IDC BioCARS roof")
##dbLoadRecords("$(DEVIOCSTATS)/iocAdminLib/Db/ioc.db","IOCNAME=14IDC")
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminVxWorks.db","IOC=14IDC")

dbLoadTemplate "iocEnvVar.substitutions"


< ../save_restore.cmd
save_restoreSet_status_prefix("14IDC:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14IDC:")

##
# IOC INIT
#

iocInit

##save_restoreSet_FilePermissions(0666)
create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# set KB mirrors pitch pm4 and pm8

dbpf "14IDC:pm4C1","-4.301"
dbpf "14IDC:pm8C1","-4.301"


seq &mirror, "P=14IDC:, mir = mir1, Y1=m1, Y2=m2, Y3=m3,  GEOM=1"
seq &Hmirror, "P=14IDC:,mir=mir2,Y1=m9,Y2=m10,Y3=m11,X1=m12,X2=m13,GEOM=1"
