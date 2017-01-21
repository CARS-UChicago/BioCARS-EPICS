
# BEGIN ethernet.cmd ---------------------------------------------------------

# Delta Tau Turbo PMAC2 Clipper in ALIO goniometer control chassis

# pmacAsynIPConfigure(const char *port, const char *hostInfo):
#   port      Asyn port for PMAC ASCII communicatons.
#   hostInfo  Hostname or IP address followed by colon followed by IP port.
pmacAsynIPConfigure("pmacAliog","164.54.161.40:1025")

# pmacAsynMotorCreate(char *port, int address, int card, int naxes):
#   port     Asyn port for PMAC ASCII communicatons.
#   address  Asyn port address.  Always 0.
#   card     Card number to use.  Is not necessarily the same card # used in
#            the other initialization routines, but probably should be.
#   naxes    Number of axes to configure.
pmacAsynMotorCreate("pmacAliog",0,0,4)

# pmacAsynCoordCreate(char *port, int addr, int cs, int ref, int program):
#   port     Asyn port for PMAC ASCII communicatons.
#   addr     Asyn port address.  Usually 0.
#   cs       Coordinate system to control (1 based).
#   ref      Unique reference used by higher level software to reference this
#            C.S.; suggest ref = cs
#   program  PMAC program number to run to move this C.S.
pmacAsynCoordCreate("pmacAliog",0,1,1,7)

# pmacSetCoordStepsPerUnit(int ref, int axis, double stepsPerUnit)
#   ref           The CS ref
#   axis          The axis number (0 based).
#   stepsPerUnit  Number of motor steps per real user unit
pmacSetCoordStepsPerUnit(1,0,5597.86667)

# (Optional) Asyn record
dbLoadRecords("$(ASYN)/db/asynRecord.db","P=14idb:,R=asyn_pmacAliog,PORT=pmacAliog,ADDR=0,OMAX=256,IMAX=256")

# drvAsynMotorConfigure(char *port, char *drvSup, int card, int nAxes):
#   port    drvAsynMotor asyn port to be created.
#   drvSup  Driver support entry table name for driver.  For PMAC, this is
#           pmacAsynMotor or pmacAsynCoord.
#   card    Card number.  For drvSup=pmacAsynMotor, this is card from
#           pmacAsynMotorCreate.  For drvSup=pmacAsynCoord, this is ref from
#           pmacAsynCoordCreate.
#   nAxes   number of axes to configure (0 based).  For drvSup=pmacAsynMotor,
#           axes are 1 based.  This means this parameter should be one more
#           than the number of axes desired.  It also means each axis is
#           referenced as a 1 based index.  For example, motor 1 is referenced
#           by motor record OUT="@asyn(<port>,1)".  Since drvAsynMotor axes
#           are 0 based, this will generate a non-fatal warning of the form:
#           "<datestamp> drvAsynMotorConfigure: Failed to open axis 0."  For
#           drvSup=pmacAsynCoord, axes are 0 based, so no special finagling of
#           this parameter is required.  Each axis is referenced as a 0 based
#           index.  For example, axis A is referenced by motor record
#           OUT="@asyn(<port>,0)".
drvAsynMotorConfigure("pmacAliogAsynMotor","pmacAsynMotor",0,5)
drvAsynMotorConfigure("pmacAliogAsynCoord","pmacAsynCoord",1,1)

# Exphi interface for exposure shutter synchronization with Phi
# malloc size for str is (numberOfLines * charsPerLineString) + sizeOfNullChar
#str=malloc((2*64)+1)
#strcpy(str,"P=14IDB:,E=Exphi,PORT=pmacAliog,TMOT=3.0,AV=P1,OPV=P2,CPV=P3,")
#strcat(str,"EPEV=P4,EPV=P5,MTV=P6,SV=P7,EV=P8,SP=8,OP=3,PP=3,DESC='14-ID-B'")
dbLoadRecords("$(CARS)/CARSApp/Db/exphi.db","P=14IDB:,E=Exphi,PORT=pmacAliog,TMOT=3.0,AV=P1,OPV=P2,CPV=P3,EPEV=P4,EPV=P5,MTV=P6,SV=P7,EV=P8,SP=8,OP=3,PP=3,DESC='14-ID-B'")

# ALIO Goniometer
dbLoadRecords("$(ALIOG)/db/aliog.db","P=14IDB:,D=alio1,DESC=14-ID-B")
#dbLoadRecords("$(ALIOG)/aliogApp/Db/sim/imcais.db","P=14IDB:,D=alio1,I=Is")

# END ethernet.cmd -----------------------------------------------------------
