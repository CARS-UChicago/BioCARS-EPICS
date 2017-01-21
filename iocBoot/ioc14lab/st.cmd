# Apr 18, 2006


sysClkRateSet 120

# vxWorks startup file
#
##
# install nfs
#
< ../nfsCommands

#hostAdd "testbed","164.54.161.66"
#nfsAuthUnixSet "testbed", 501,500,0
#nfsMount("testbed","/home/epics/epics_scans")

< cdCommands
# Need to add this back in during the downtime


cd topbin

load("CARS.munch")


cd startup
# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in this build from CARS
dbLoadDatabase("$(CARS)/dbd/iocCARSVX.dbd")
iocCARSVX_registerRecordDeviceDriver(pdbbase)

errlogInit(50000)

# Currently, the only thing we do in initHooks is call reboot_restore(), which
# restores positions and settings saved ~continuously while EPICS is alive.
# See calls to "create_monitor_set()" at the end of this file.  To disable
# autorestore, comment out the following line.
#ld < initHooks.o




< industryPack.cmd

#####< serial.cmd

< softGlue.cmd



dbLoadRecords("$(STD)/stdApp/Db/scaler.db","C=0,P=14LAB:,S=sclS1,OUT=#C0 S0 @,FREQ=1e7,DTYP=Joerger VSC8/16")

# Scan record
dbLoadRecords("$(SSCAN)/sscanApp/Db/scan.db","P=14LAB:,MAXPTS1=2000,MAXPTS2=200,MAXPTS3=20,MAXPTS4=10,MAXPTSH=10")


# XIA shutter
#dbLoadRecords("$(CARS)/CARSApp/Db/xiaShutter4.db","P=14LAB:")
dbLoadRecords("$(CARS)/CARSApp/Db/xiaShutter8ms.db","P=14LAB:,PHI=m2,OMEGA=m4")




dbLoadRecords("$(CARS)/CARSApp/Db/M6VALCOpump.db","P=14LAB:,DEVICE=M6,PORT=serial5")

dbLoadRecords("$(CARS)/CARSApp/Db/VALCOvalve.db","P=14LAB:,DEVICE=V10,PORT=serial4")

# Joerger VSC setup parameters:
#     (1)cards, (2)base address(ext, 256-byte boundary),
#     (3)interrupt vector (0=disable or  64 - 255)
# Can't use D000000 on PowerPC, change to B0000000
VSCSetup (1, 0xB0000000, 200)

# Oms58-8S servo card
#oms58Setup(number of cards, unused, base address, interrupt vector, interupt level, poll rate)
######## IK removed the last card to install for KB mirrors!
########oms58Setup(1, 0x4000, 190, 5, 60)

# OMS MAXv driver setup parameters:
#     (1)number of cards in array.
#     (2)VME Address Type (16,24,32).
#     (3)Base Address on 4K (0x1000) boundary.
#     (4)interrupt vector (0=disable or  64 - 255).
#     (5)interrupt level (1 - 6).
#     (6)motor task polling rate (min=1Hz,max=60Hz).
#MAXvSetup(1, 16, 0xF000, 190, 5, 10)
MAXvSetup(1, 16, 0x4000, 190, 5, 10)
 
drvMAXvdebug=4
 
# OMS MAXv configuration string:
#     (1) number of card being configured (0-14).
#     (2) configuration string; axis type (PSO/PSE/PSM) MUST be set here.
#         For example, set which TTL signal level defines
#         an active limit switch.  Set X,Y,Z,T to active low and set U,V,R,S
#         to active high.  Set all axes to open-loop stepper (PSO). See MAXv
#         User's Manual for LL/LH and PSO/PSE/PSM commands.
#config0="AX LL PSO; AY LL PSO; AZ LL PSO; AT LL PSO; AU LH PSO; AV LH PSO; AR LH PSO; AS LH PSO;"
#!config0="AX LH PSM; AY LL PSO; AZ LL PSO; AT LL PSO; AU LH PSO; AV LH PSO; AR LH PSO; AS LH PSO;"
                                                                                
# Set all axes to open-loop stepper and active high limits
config0="AX LH PSO; AY LH PSO; AZ LH PSO; AT LH PSO; AU LH PSO; AV LH PSO; AR LH PSO; AS LH PSO;"
# Set all to active low limits for ThorLabs micrometers.  Set all to servo.
#config0="AX LL PSM; AY LL PSM; AZ LL PSM; AT LL PSM; AU LL PSM; AV LL PSM; AR LL PSM; AS LL PSM;"
config0="AX LH PSO; AY LL PSO; AZ LL PSO; AT LL PSO; AU LH PSO; AV LH PSO; AR LH PSO; AS LH PSO;"
MAXvConfig(0, config0)
dbLoadTemplate "14LAB.MAXv.template"

# Configure Analogic DVX 2503 A/D
#dvx2502Config(ncards, base, memory, vector)
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

# Configure Acromag AVME 9440 Binary I/O (ncards, a16base, intvecbase)
devAvme9440Config(1,0xA000,220)

#Configure DAC
avme9210Config(1, 8, 0x3000)

dbLoadTemplate "14LAB.DAC.template"
dbLoadTemplate "14LAB.ADC.template"

#iocLogDisable=0
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminVxWorks.db","IOC=14LAB")

< ../save_restore.cmd
save_restoreSet_status_prefix("14LAB:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14LAB:")

iocInit

create_monitor_set("auto_positions.req", 5)
create_monitor_set("auto_settings.req", 30)

# This will store the initial settings of the SRS570.  Comment out after 
# the first use.
#create_monitor_set("SRS570_settings.req",5.0)

# The will read in the settings for the SRS570 which was created by the above command.
#reboot_restore("SRS570_settings.sav")


saveData_MessagePolicy = 2
saveData_SetCptWait_ms(100)
saveData_Init("saveDataExtraPVs.req", "P=14LAB:")




