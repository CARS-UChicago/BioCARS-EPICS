errlogInit(5000)
< envPaths
epicsEnvSet(STARTUP,$(TOP)/iocBoot/$(IOC))
dbLoadDatabase("../../dbd/iocCARSLinux.dbd")
iocCARSLinux_registerRecordDeviceDriver(pdbbase)


# Tell EPICS all about the record types, device-support modules, drivers,
# etc. in this build
#dbLoadDatabase("../../dbd/quadEMTestApp.dbd")
dbLoadDatabase("$(QUADEM)/dbd/quadEMTestApp.dbd")
##############################quadEMTestApp_registerRecordDeviceDriver(pdbbase)

# The search path for database files
# Note: the separator between the path entries needs to be changed to a semicolon (;) on Windows
epicsEnvSet("EPICS_DB_INCLUDE_PATH", "$(ADCORE)/db:$(QUADEM)/db")

< AH401B.cmd
