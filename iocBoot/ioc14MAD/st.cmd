# Linux startup script
cd /home/epics/support/CARS/iocBoot/ioc14MAD
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

# Setup scan record which does not write to a file
dbLoadRecords("$(SSCAN)/sscanApp/Db/scanAux.db","P=14IDB:")

# A set of scan parameters for each positioner.  This is a convenience
# for the user.  It can contain an entry for each scannable thing in the
# crate.
dbLoadTemplate("scanParmsMAD.template")
dbLoadTemplate("scanParmsLaue.template")
#dbLoadTemplate("14MAD.RemoteShutter.template")

# Testing of New Energy Scans template - IK
dbLoadTemplate("scanParmsIDB_MAD.template")

# This is temperary. I put it here so that I didn't have to reboot the crate. Need to move into crate later
#dbLoadTemplate("scanParms.template")

# 4-step measurement
#dbLoadRecords("$(STD)/stdApp/Db/4step.db", "P=CARS:")
# interpolation
#dbLoadRecords("$(CALC)/calcApp/Db/interp.db", "P=CARS:,N=2000")

# Test Channel Cut database
#dbLoadRecords("IDB_Channel_Cut.db","P=14IDB:")

#Test Laser Flag database
#dbLoadRecords("$(CARS)/CARSApp/Db/psLaserFlag.db","P=14IDB:, R=2")

#Test DetectortriggerScope database
#dbLoadRecords("$(CARS)/CARSApp/Db/DetectorTriggerScope.db","P=14IDB:")


# Combined motion for ADC slits- dispersion exp temp
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDB:,SLIT=Slit1V,mXp=m57,mXn=m58")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=14IDB:,SLIT=Slit1H,mXp=m59,mXn=m60")

#Test PID parameters database
# ATTN commented out for testing; uncomment for monochromatic
dbLoadRecords("$(CARS)/CARSApp/Db/PIDparameters.db","P1=14IDB:,P2=14IDA:, Q=PID")

# Test Table BeamCheck alignment
#dbLoadRecords("$(CARS)/CARSApp/Db/beamCheckTbl.db","P=14IDB:")

# ATTN commented out for testing; uncomment for monochromatic
dbLoadRecords("$(CARS)/CARSApp/Db/beamCheckMono.db","P=14IDB:")

#dbLoadRecords("$(CARS)/CARSApp/Db/14IDB_table_angle.db","P=14IDB:")
#dbLoadRecords("$(CARS)/CARSApp/Db/psLaserShutter.db","P=14IDB:")

#dbLoadRecords("$(CARS)/CARSApp/Db/SaveSamplePositions.db","P=14IDB:,Q=SP,M1=ESP300X,M2=ESP300Y,M3=ESP300Z")

#use vortex dummy in monochromatic mode, when no detector is present
#comment out if detector is installed
dbLoadRecords("VortexDummy.db","D=dxpSaturn")

# Multichannel analyzer stuff
# Copied from the ioc14idb crate because we didn't want to reboot the crate. RH 4/1/11
# AIMConfig(mpfServer, card, ethernet_address, port, maxChans, 
#           maxSignals, maxSequences, ethernetDevice, queueSize)
##AIMConfig("AIM/1", 0xC49, 1, 2048, 1, 1, "fei0")
##dbLoadRecords("$(MCA)/mcaApp/Db/mca.db", "P=14IDB:,M=aim_adc1,DTYP=asynMCA,INP=@asyn(AIM/1 0),NCHAN=2048")

##icbConfig("icb/1", 0xC49, 1, 0)
##dbLoadRecords("$(MCA)/mcaApp/Db/icb_adc.db", "P=14IDB:,ADC=adc1,PORT=icb/1")


# Testing of New Energy Scans template - IK
# dbLoadTemplate("$(CARS)/iocBoot/ioc14ida/14IDA.RemoteShutterMod.template")

# Testing of Move Laser Motors
# commented out for testing 5-2012
#dbLoadRecords("$(CARS)/CARSApp/Db/LaserMotorsSeq.db","P=14IDB:,P1=14IDLL:, P2=14IDC:")


# Testing of LA2000 FAULTS prototype - IK
#dbLoadRecords("$(CARS)/CARSApp/Db/test.db","P=14IDB:,R=1:")
###############################################################################
iocInit

# save positions every five seconds
#create_monitor_set("auto_positions.req",5,"P=CARS:")
# save other things every thirty seconds
create_monitor_set("auto_settings.req",30,"P=CARS:")

#seq &beamCheckTbl

# uncomment beamCheckMono and IDB_MAD for further use


seq &beamCheckMono, " P1=14IDA:, P2=14IDB:, M=m12, D=DAC1_3 "

seq &IDB_MAD, "P1=14IDA:, P2=14IDB:, P3=14IDC:, M1=m12, M2=m3, M3=m8, M4=m27, M5=m25"



