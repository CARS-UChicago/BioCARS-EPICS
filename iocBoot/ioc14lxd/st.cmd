cd /home/epics/support/CARS/iocBoot/ioc14lxd
< envPaths

epicsEnvSet(STARTUP,$(TOP)/iocBoot/$(IOC))
errlogInit(20000)
epicsEnvSet EPICS_CA_MAX_ARRAY_BYTES 64008

dbLoadDatabase("../../dbd/iocCARSLinux.dbd")
iocCARSLinux_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("lxd.db","P=14IDB:")

< save_restore.cmd

###############################################################################
iocInit

# save positions every five seconds
#create_monitor_set("auto_positions.req",5,"P=CARS:")
# save other things every thirty seconds
create_monitor_set("auto_settings.req",30,"P=CARS:")

#seq &IDB_MAD, "P1=14IDA:, P2=14IDB:, P3=14IDC:, M1=m12, M2=m3, M3=m8, M4=m27, M5=m25"
seq &lxd


