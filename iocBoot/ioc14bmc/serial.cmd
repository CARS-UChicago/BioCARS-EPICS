# int tyGSAsynInit(char *port, int uart, int channel, int baud, char parity, int sbits,
#                 int dbits, char handshake, char *inputEos, char *outputEos)
tyGSAsynInit("serial1",  "UART0", 0, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Ion Chamber 1 */
tyGSAsynInit("serial2",  "UART0", 1, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Table Diode */
tyGSAsynInit("serial3",  "UART0", 2, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Ion Chamber 2 */
tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 AUX */
tyGSAsynInit("serial5",  "UART0", 4,19200,'N',1,8,'Y',"\r","\r")  /* ESP300 */
tyGSAsynInit("serial6",  "UART0", 5, 9600,'N',2,8,'N',"\r","\r")  /* ILM cryo level */
tyGSAsynInit("serial7",  "UART0", 6, 9600,'N',1,8,'N',"\r","\r")  /* oxford cryo controller*/
tyGSAsynInit("serial8",  "UART0", 7,19200,'N',1,8,'N',"\r","\r")  /* MCB4B */

## add 10-7-10 IK
tyGSAsynInit("serial9",  "UART1", 0, 9600,'N',1,8,'N',"\r\n","\r")  /*VALCO M6 */
tyGSAsynInit("serial10", "UART1", 1, 9600,'N',1,8,'N',"\r","\r")  /* VALCO V10 */
#tyGSAsynInit("serial10", "UART1", 1, 19200,'N',1,8,'Y',"\r","\r")  /* ESP300 */
tyGSAsynInit("serial11", "UART1", 2, 9600,'N',1,8,'N',"\r","\r")  /*  VALCO V10*/
tyGSAsynInit("serial12", "UART1", 3, 9600,'N',1,8,'N',"\r","\r")  /*  */
tyGSAsynInit("serial13", "UART1", 4, 9600,'N',2,8,'N',"\r","\r")  /* */
tyGSAsynInit("serial14", "UART1", 5, 9600,'N',1,8,'N',"\n","")    /*  */
tyGSAsynInit("serial15", "UART1", 6, 9600,'N',1,8,'N',"\r","\r")  /**/
tyGSAsynInit("serial16", "UART1", 7, 9600,'N',1,7,'N',"\r","\r")  /*  */




# Set up first 2 ports on Moxa box
drvAsynIPPortConfigure("serial20", "164.54.161.101:4001", 0, 0, 1)
drvAsynIPPortConfigure("serial21", "164.54.161.101:4002", 0, 0, 1)
drvAsynIPPortConfigure("serial22", "164.54.161.101:4003", 0, 0, 1)
dbLoadRecords("$(CARS)/CARSApp/Db/spherosyn.db", "P=14BMC:, E=dz, PORT=serial20, B=313865600, D=200,STOP=dz")
dbLoadRecords("$(CARS)/CARSApp/Db/spherosyn.db", "P=14BMC:, E=dyu, PORT=serial21, B=79558, D=-203.19,STOP=dY")
dbLoadRecords("$(CARS)/CARSApp/Db/spherosyn.db", "P=14BMC:, E=dyd, PORT=serial22, B=84218, D=-203.19,STOP=dY")


# Keithley 2701
#drvAsynIPPortConfigure("serial9","192.168.4.44:1394",0,0,0)
#asynOctetConnect("serial9","serial9")
 
#dbLoadRecords("$(IP)/ipApp/Db/Keithley2kDMM_mf.db","P=14BMC:,Dmm=DMM1,PORT=serial9")


# Make these ports available from the iocsh command line
#asynOctetConnect("serial20", "serial20", 0, 1, 80)
#asynOctetConnect("serial21", "serial21", 0, 1, 80)

# GPIB addresses: 1=Tektronix scope, 2=Keithley 2000, 3=Fluke meter
#asynInterposeEosConfig("gpib1", 1, 1, 0)
#asynOctetSetInputEos("gpib1", 1, "\n")
#asynOctetConnect("gpib1:1", "gpib1", 1, 1, 80)
#asynOctetConnect("gpib1:2", "gpib1", 2, 1, 80)
#asynInterposeEosConfig("gpib1", 3, 1, 0)
#asynOctetSetInputEos("gpib1", 3, "\r")
#asynOctetConnect("gpib1:3", "gpib1", 3, 1, 80)

# Load asynRecord records on all ports
dbLoadTemplate("asynRecord.template")

# Serial 1-4 Stanford Research Systems SR570 Current Preamplifier
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMC:,A=A1,PORT=serial1")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMC:,A=A2,PORT=serial2")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMC:,A=A3,PORT=serial3")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMC:,A=A4,PORT=serial4")

dbLoadRecords("$(CARS)/CARSApp/Db/oxford_ILM200.db","P=14BMC:,R=ILM,PORT=serial6")
dbLoadRecords("$(CARS)/CARSApp/Db/oxfordCryoRead.db","P=14BMC:,PORT=serial7")


# Serial 4 MCB4B motor controller
# MCB-4B driver setup parameters:
#     (1) maximum # of controllers,
#     (2) motor task polling rate (min=1Hz, max=60Hz)
MCB4BSetup(1, 10)

# MCB-4B driver configuration parameters:
#     (1) controller
#     (2) asyn port name (e.g. serial1)
MCB4BConfig(0, "serial8")

########dbLoadRecords("$(DELAYGEN)/delaygenApp/Db/devDG535.db","P=14BMC:,R=DG535_1,L=0,A=1")

