errlogInit(5000)
< envPaths
# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in this build from CARS
epicsEnvSet(STARTUP,$(TOP)/iocBoot/$(IOC))
dbLoadDatabase("../../dbd/iocCARSLinux.dbd")
iocCARSLinux_registerRecordDeviceDriver(pdbbase)

##THis is for the serial port configuration I possibly move it pumps and valves software here
## this I have to figure out later. I might use Syringe software for that
## huge or #!#! comments for serial port devices stream protocol, just discomment that
#drvAsynIPPortConfigure("L0","164.54.161.204:2001",0,0,0)
#################################################drvAsynIPPortConfigure("L0","164.54.161.83:2001",0,0,0)
# We don't set terminators here, we let StreamDevice take care of it
#################################################asynSetTraceIOMask("L0",0,2)
#asynSetTraceMask("L0",0,0x9)

##comment out IK 072115
## comment out Syringe databases and asynrecord required again may need that for further work
#!#!dbLoadRecords("/home/epics/CPSyringeMod2.db", "P=14Syringe1:, R=S1:, PORT=L0")
#!#!dbLoadRecords("$(ASYN)/db/asynRecord.db", "P=14Syringe1:, R=asyn1, PORT=L0, ADDR=0, IMAX=80, OMAX=80")
dbLoadRecords("$(CARS)/CARSApp/Db/Sampler.db", "P=14AutoSampler:")

#var streamDebug 1

set_pass0_restoreFile("auto_settings.sav")
set_pass1_restoreFile("auto_settings.sav")

#< ../save_restore.cmd
#!#!save_restoreSet_status_prefix("14Syringe1:")
#!#!dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14Syringe1:")

save_restoreSet_status_prefix("14AutoSampler:")
dbLoadRecords("$(AUTOSAVE)/asApp/Db/save_restoreStatus.db", "P=14AutoSampler:")

####################################################epicsEnvSet(STREAM_PROTOCOL_PATH, $(IP)/ipApp/Db)

date
iocInit

### Start up the autosave task and tell it what to do.
# The task is actually named "save_restore".
# (See also, 'initHooks' above, which is the means by which the values that
# will be saved by the task we're starting here are going to be restored.
#
# save other things every thirty seconds
create_monitor_set("auto_settings.req", 30, "P=14AutoSampler:, R=S1:")

