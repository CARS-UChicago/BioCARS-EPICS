# Linux startup script
cd /home/epics/support.3.14.12.6/CARS/iocBoot/ioc14alio
< envPaths

# save_restore.cmd needs the full path to the startup directory, which
# envPaths currently does not provide
epicsEnvSet(startup,$(TOP)/iocBoot/$(IOC))

# Increase size of buffer for error logging from default 1256
errlogInit(20000)

# Specify largest array CA will transport
# Note for N sscanRecord data points, need (N+1)*8 bytes, else MEDM
# plot doesn't display
epicsEnvSet EPICS_CA_MAX_ARRAY_BYTES 64008

dbLoadDatabase("../../dbd/iocCARSLinux.dbd")
iocCARSLinux_registerRecordDeviceDriver(pdbbase)

# Ethernet devices
< ethernet.cmd

dbLoadTemplate("motor.substitutions")
dbLoadRecords("$(DEVIOCSTATS)/db/iocAdminSoft.db","IOC=14alio")
<save_restore2.cmd

iocInit

# save positions every five seconds
#create_monitor_set("auto_positions.req",5,"P=14IDB:")
# save other things every thirty seconds
create_monitor_set("auto_settings.req",30,"P=14IDB:")


# ALIO Goniometer
# malloc size for str is (numberOfLines * charsPerLineString) + sizeOfNullChar
#str=malloc((4*64)+1)
#strcpy(str,"P=14IDB:,D=alio1,PORT=pmacAliog,PHI=2,X=3,Y=4,Z=1,AIR=M115,")
#strcat(str,"AIRT=P907,XYDAC=P906,PHS=P1011,PPLC=10,PS=P1021,HPLC=11,")
#strcat(str,"HS=P1031,APC=0,APCS=1,AMIPP=500,ACIPP=500,I=14IDB:Is,")
#strcat(str,"E=14IDB:Exphi")
#seq(&aliogFSMs,str)
#seq(&aliogFSMs,"P=14IDB:,D=alio1,PORT=pmacAliog,PHI=2,X=3,Y=4,Z=1,AIR=M115,AIRT=P907,XYDAC=P906,PHS=P1011,PPLC=10,PS=P1021,HPLC=11,HS=P1031,APC=0,APCS=1,AMIPP=500,ACIPP=500,I=14IDB:Is,E=14IDB:Exphi")
seq(&aliogFSMs_BioCARS,"P=14IDB:,D=alio1,PORT=pmacAliog,PHI=2,X=3,Y=4,Z=1,AIR=M115,AIRT=P907,XYDAC=P810,PHS=P1011,PHPLC=2,PPLC=10,PS=P910,HPLC=11,HS=P920,APC=0,APCS=1,AMIPP=500,ACIPP=500,I=14IDB:Is,E=14IDB:Exphi")
# ...
