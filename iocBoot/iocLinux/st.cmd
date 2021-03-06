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
< serial.cmd

# Motors
#dbLoadTemplate("basic_motor.substitutions")
#dbLoadTemplate("motor.substitutions")
dbLoadTemplate("softMotor.substitutions")
#dbLoadTemplate("pseudoMotor.substitutions")
< motorSim.cmd

#< areaDetector.cmd

### Allstop, alldone
# This database must agree with the motors and other positioners you've actually loaded.
# Several versions (e.g., all_com_32.db) are in stdApp/Db
dbLoadRecords("$(MOTOR)/db/motorUtil.db", "P=CARS:")

### Insertion-device control
#dbLoadRecords("$(STD)/stdApp/Db/IDctrl.db","P=CARS:,xx=02us")

# sample-wheel
#dbLoadRecords("$(STD)/stdApp/Db/sampleWheel.db", "P=CARS:,ROWMOTOR=CARS:m7,ANGLEMOTOR=CARS:m8")

### Scan-support software
# crate-resident scan.  This executes 1D, 2D, 3D, and 4D scans, and caches
# 1D data, but it doesn't store anything to disk.  (See 'saveData' below for that.)
dbLoadRecords("$(SSCAN)/sscanApp/Db/scan.db","P=CARS:,MAXPTS1=8000,MAXPTS2=1000,MAXPTS3=10,MAXPTS4=10,MAXPTSH=8000")

# A set of scan parameters for each positioner.  This is a convenience
# for the user.  It can contain an entry for each scannable thing in the
# crate.
#dbLoadTemplate("scanParms.substitutions")

### Slits
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=CARS:,SLIT=Slit1V,mXp=m3,mXn=m4")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit.db","P=CARS:,SLIT=Slit1H,mXp=m5,mXn=m6")

# under development...
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit_soft.db","P=CARS:,SLIT=Slit2V,mXp=m13,mXn=m14")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2slit_soft.db","P=CARS:,SLIT=Slit2H,mXp=m15,mXn=m16")

# X-ray Instrumentation Associates Huber Slit Controller
# supported by a customized version of the SNL program written by Pete Jemian
#dbLoadRecords("$(OPTICS)/opticsApp/Db/xia_slit.db", "P=CARS:, HSC=hsc1:")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/xia_slit.db", "P=CARS:, HSC=hsc2:")
#dbLoadRecords("$(IP)/ipApp/Db/generic_serial.db", "P=CARS:,C=0,SERVER=serial7")


### 2-post mirror
#dbLoadRecords("$(OPTICS)/opticsApp/Db/2postMirror.db","P=CARS:,Q=M1,mDn=m18,mUp=m17,LENGTH=0.3")

### User filters
#dbLoadRecords("$(OPTICS)/opticsApp/Db/filterMotor.db","P=CARS:,Q=fltr1:,MOTOR=m1,LOCK=fltr_1_2:")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/filterMotor.db","P=CARS:,Q=fltr2:,MOTOR=m2,LOCK=fltr_1_2:")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/filterLock.db","P=CARS:,Q=fltr2:,LOCK=fltr_1_2:,LOCK_PV=CARS:DAC1_1.VAL")

### Optical tables
#tableRecordDebug=1
#dbLoadRecords("$(OPTICS)/opticsApp/Db/table.db","P=CARS:,Q=Table1,T=table1,M0X=m1,M0Y=m2,M1Y=m3,M2X=m4,M2Y=m5,M2Z=m6,GEOM=SRI")

### Monochromator support ###
# Kohzu and PSL monochromators: Bragg and theta/Y/Z motors
# standard geometry (geometry 1)
#dbLoadRecords("$(OPTICS)/opticsApp/Db/kohzuSeq.db","P=CARS:,M_THETA=m9,M_Y=m10,M_Z=m11,yOffLo=17.4999,yOffHi=17.5001")
# modified geometry (geometry 2)
#dbLoadRecords("$(OPTICS)/opticsApp/Db/kohzuSeq.db","P=CARS:,M_THETA=m9,M_Y=m10,M_Z=m11,yOffLo=4,yOffHi=36")

# Spherical grating monochromator
#dbLoadRecords("$(OPTICS)/opticsApp/Db/SGM.db","P=CARS:,N=1,M_x=m7,M_rIn=m6,M_rOut=m8,M_g=m9")

# 4-bounce high-resolution monochromator
#dbLoadRecords("$(OPTICS)/opticsApp/Db/hrSeq.db","P=CARS:,N=1,M_PHI1=m9,M_PHI2=m10")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/hrSeq.db","P=CARS:,N=2,M_PHI1=m11,M_PHI2=m12")

### Orientation matrix, four-circle diffractometer (see seq program 'orient' below)
#dbLoadRecords("$(OPTICS)/opticsApp/Db/orient.db", "P=CARS:,O=1,PREC=4")
#dbLoadTemplate("orient_xtals.substitutions")

# Load single element Canberra AIM MCA and ICB modules
#< canberra_1.cmd

# Load 13 element detector software
#< canberra_13.cmd

# Load 3 element detector software
#< canberra_3.cmd

### Stuff for user programming ###
dbLoadRecords("$(CALC)/calcApp/Db/userCalcs10.db","P=CARS:")
dbLoadRecords("$(CALC)/calcApp/Db/userCalcOuts10.db","P=CARS:")
dbLoadRecords("$(CALC)/calcApp/Db/userStringCalcs10.db","P=CARS:")
var aCalcArraySize, 2000
dbLoadRecords("$(CALC)/calcApp/Db/userArrayCalcs10.db","P=CARS:,N=2000")
dbLoadRecords("$(CALC)/calcApp/Db/userTransforms10.db","P=CARS:")
# extra userCalcs (must also load userCalcs10.db for the enable switch)
dbLoadRecords("$(CALC)/calcApp/Db/userCalcN.db","P=CARS:,N=I_Detector")
dbLoadRecords("$(CALC)/calcApp/Db/userAve10.db","P=CARS:")
# string sequence (sseq) record
dbLoadRecords("$(STD)/stdApp/Db/yySseq.db","P=CARS:,S=Sseq1")
dbLoadRecords("$(STD)/stdApp/Db/yySseq.db","P=CARS:,S=Sseq2")
dbLoadRecords("$(STD)/stdApp/Db/yySseq.db","P=CARS:,S=Sseq3")
# 4-step measurement
dbLoadRecords("$(STD)/stdApp/Db/4step.db", "P=CARS:")
# interpolation
dbLoadRecords("$(CALC)/calcApp/Db/interp.db", "P=CARS:,N=2000")
# array test
dbLoadRecords("$(CALC)/calcApp/Db/arrayTest.db", "P=CARS:,N=2000")

# Slow feedback
#dbLoadTemplate "pid_slow.substitutions"

# Miscellaneous PV's, such as burtResult
dbLoadRecords("$(STD)/stdApp/Db/misc.db","P=CARS:")
#dbLoadRecords("$(STD)/stdApp/Db/VXstats.db","P=CARS:")

### Queensgate piezo driver
#dbLoadRecords("$(IP)/ipApp/Db/pzt_3id.db","P=CARS:")
#dbLoadRecords("$(IP)/ipApp/Db/pzt.db","P=CARS:")

### Queensgate Nano2k piezo controller
#dbLoadRecords("$(STD)/stdApp/Db/Nano2k.db","P=CARS:,S=s1")

### Load database records for Femto amplifiers
#dbLoadRecords("$(STD)/stdApp/Db/femto.db","P=CARS:,H=fem01:,F=seq01:")

### Load database records for dual PF4 filters
#dbLoadRecords("$(OPTICS)/opticsApp/Db/pf4common.db","P=CARS:,H=pf4:,A=A,B=B")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/pf4bank.db","P=CARS:,H=pf4:,B=A")
#dbLoadRecords("$(OPTICS)/opticsApp/Db/pf4bank.db","P=CARS:,H=pf4:,B=B")

###############################################################################
iocInit

### startup State Notation Language programs
#seq &kohzuCtl, "P=CARS:, M_THETA=m9, M_Y=m10, M_Z=m11, GEOM=1, logfile=kohzuCtl.log"
#seq &hrCtl, "P=CARS:, N=1, M_PHI1=m9, M_PHI2=m10, logfile=hrCtl1.log"

# Keithley 2000 series DMM
# channels: 10, 20, or 22;  model: 2000 or 2700
#seq &Keithley2kDMM,("P=CARS:, Dmm=D1, channels=22, model=2700")

# X-ray Instrumentation Associates Huber Slit Controller
# supported by a SNL program written by Pete Jemian and modified (TMM) for use with the
# sscan record
#seq  &xia_slit, "name=hsc1, P=CARS:, HSC=hsc1:, S=CARS:seriala[6]"

# Orientation-matrix
#seq &orient, "P=CARS:orient1:,PM=CARS:,mTTH=m9,mTH=m10,mCHI=m11,mPHI=m12"

# Start PF4 filter sequence program
#seq pf4,"name=pf1,P=CARS:,H=pf4:,B=A,M=CARS:BraggEAO,B1=CARS:Unidig1Bo3,B2=CARS:Unidig1Bo4,B3=CARS:Unidig1Bo5,B4=CARS:Unidig1Bo6"
#seq pf4,"name=pf2,P=CARS:,H=pf4:,B=B,M=CARS:BraggEAO,B1=CARS:Unidig1Bo7,B2=CARS:Unidig1Bo8,B3=CARS:Unidig1Bo9,B4=CARS:Unidig1Bo10"

# Start Femto amplifier sequence programs
#seq femto,"name=fem1,P=CARS:,H=fem01:,F=seq01:,G1=CARS:Unidig1Bo6,G2=CARS:Unidig1Bo7,G3=CARS:Unidig1Bo8,NO=CARS:Unidig1Bo10"

### Start up the autosave task and tell it what to do.
# The task is actually named "save_restore".
# Note that you can reload these sets after creating them: e.g., 
# reload_monitor_set("auto_settings.req",30,"P=CARS:")
#save_restoreDebug=20
#
# save positions every five seconds
create_monitor_set("auto_positions.req",5,"P=CARS:")
# save other things every thirty seconds
create_monitor_set("auto_settings.req",30,"P=CARS:")

### Start the saveData task.
saveData_Init("saveData.req", "P=CARS:")

dbcar(0,1)

# motorUtil (allstop & alldone)
motorUtilInit("CARS:")

