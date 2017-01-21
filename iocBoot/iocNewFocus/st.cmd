# Linux startup script

< envPaths

# save_restore.cmd needs the full path to the startup directory, which
# envPaths currently does not provide
epicsEnvSet(STARTUP,$(TOP)/iocBoot/$(IOC))

# Increase size of buffer for error logging from default 1256
errlogInit(20000)

# Specify largest array CA will transport
# Note for N sscanRecord data points, need (N+1)*8 bytes, else MEDM
# plot doesn't display
epicsEnvSet EPICS_CA_MAX_ARRAY_BYTES 64008

################################################################################
# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in the software we just loaded (CARS.munch)
dbLoadDatabase("../../dbd/iocCARSLinux.dbd")
iocCARSLinux_registerRecordDeviceDriver(pdbbase)

### save_restore setup
# We presume a suitable initHook routine was compiled into CARS.munch.
# See also create_monitor_set(), after iocInit() .
< save_restore.cmd

# serial support
#< serial.cmd
dbLoadTemplate("motor.substitutions")

drvAsynIPPortConfigure("serial3", "164.54.161.85:23", 0, 0, 0)
asynOctetSetInputEos("serial3",0,">")
asynOctetSetOutputEos("serial3",0,"\r")

# New Focus Picomotor Network Controller (model 8750/2) (setup parameters:  
#     (1) maximum number of controllers in system 
#     (2) maximum number of drivers per controller (1 - 3)  
#     (3) motor task polling rate (min=1Hz,max=60Hz)  
PMNC87xxSetup(1, 2, 10) 
 
# New Focuc Picomotor Network Controller (model 8750/2) configuration parameters:  
#     (1) controller# being configured, 
#     (2) asyn port name (string)
PMNC87xxConfig(0, "serial3")
#!drvPMNC87xxdebug=4

###############################################################################
iocInit

### startup State Notation Language programs

### Start up the autosave task and tell it what to do.
# The task is actually named "save_restore".
# Note that you can reload these sets after creating them: e.g., 
# reload_monitor_set("auto_settings.req",30,"P=CARS:")
#save_restoreDebug=20
#
# save positions every five seconds
create_monitor_set("auto_positions.req",5,"P=14IDB:")
# save other things every thirty seconds
create_monitor_set("auto_settings.req",30,"P=14IDB:")

### Start the saveData task.
saveData_Init("saveData.req", "P=14IDB:")

#dbcar(0,1)


