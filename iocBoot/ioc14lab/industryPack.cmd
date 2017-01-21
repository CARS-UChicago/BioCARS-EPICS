ll

ipacAddTVME200("201FA0")
#ipacAddVIPC616_01("0x2000,0xa0000000")
#ipacAddVIPC616_01("0x3400,0xa2000000")



ipacReport(2)

# gsIP488Configure(char *portName, int carrier, int module, int vector,
#                  unsigned int priority, int noAutoConnect)
#gsIP488Configure("gpib1",0,2,0x69,0,0) 
    
tyGSOctalDrv 1
tyGSOctalModuleInit("UART0","GSIP_OCTAL232", 0x80, 0, 0)
#tyGSOctalModuleInit("GSIP_OCTAL232", 0x81, 1, 2)

# Initialize Greenspring IP-Unidig
# initIpUnidig(char *portName, 
#              int carrier, 
#              int slot,
#              int msecPoll,
#              int intVec, 
#              int risingMask, 
#              int fallingMask,
#              int biMask,
#              int maxClients)
# portName  = name to give this asyn port
# carrier     = IPAC carrier number (0, 1, etc.)
# slot        = IPAC slot (0,1,2,3, etc.)
# msecPoll    = polling time for input bits in msec.  Default=100.
# intVec      = interrupt vector
# risingMask  = mask of bits to generate interrupts on low to high (24 bits)
# fallingMask = mask of bits to generate interrupts on high to low (24 bits)
#initIpUnidig("Unidig1", 0, 1, 2000, 116, 0xfffffb, 0xfffffb)
#dbLoadTemplate "ipUnidig.substitutions"

# Initialize Systran DAC
# initDAC128V(char *portName, int carrier, int slot)
# portName  = name to give this asyn port
# carrier     = IPAC carrier number (0, 1, etc.)
# slot        = IPAC slot (0,1,2,3, etc.)
#initDAC128V("DAC1", 0, 3)
initDAC128V("DAC2", 0, 2)
#dbLoadTemplate "14LAB_DAC.template"
#
# Initialize Acromag IP-330 ADC
# initIp330(
#   const char *portName, int carrier, int slot,
#   const char *typeString, const char *rangeString,
#   int firstChan, int lastChan,
#   int intVec)
# portName    = name to give this asyn port
# carrier     = IPAC carrier number (0, 1, etc.)
# slot        = IPAC slot (0,1,2,3, etc.)
# typeString  = "D" or "S" for differential or single-ended
# rangeString = "-5to5","-10to10","0to5", or "0to10"
#               This value must match hardware setting selected
# firstChan   = first channel to be digitized.  This must be in the range:
#               0 to 31 (single-ended)
#               0 to 15 (differential)
# lastChan    = last channel to be digitized
# intVec        Interrupt vector
#initIp330("Ip330_1",0,2,"D","-10to10",0,15,120)

# int configIp330(
#   const char *portName,
#   int scanMode, const char *triggerString,
#   int microSecondsPerScan, int secondsBetweenCalibrate)
# portName    = name of aysn port created with initIp330
# scanMode    = scan mode:
#               0 = disable
#               1 = uniformContinuous
#               2 = uniformSingle
#               3 = burstContinuous (normally recommended)
#               4 = burstSingle
#               5 = convertOnExternalTriggerOnly
# triggerString = "Input" or "Output". Selects the direction of the external
#               trigger signal.
# microSecondsPerScan = repeat interval to digitize all channels
#               The minimum theoretical time is 15 microseconds times the
#               number of channels, but a practical limit is probably 100
#               microseconds.
# secondsBetweenCalibrate = number of seconds between calibration cycles.
#               If zero then there will be no periodic calibration, but
#               one calibration will still be done at initialization.
#configIp330("Ip330_1", 3,"Input",1000,0)

# int initFastSweep(char *portName, char *inputName, 
#                   int maxSignals, int maxPoints)
# portName   = asyn port name for this port
# inputName  = name of input port
# maxSignals = maximum number of input signals.
# maxPoints  = maximum number of points in a sweep.  The amount of memory
#              allocated will be maxPoints*maxSignals*4 bytes
#initFastSweep("Ip330Sweep1","Ip330_1", 4, 2048)
#dbLoadTemplate "Ip330_ADC.template"



