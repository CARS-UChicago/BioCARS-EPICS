# int tyGSAsynInit(char *port, int uart, int channel, int baud, char parity, int sbits,
#                 int dbits, char handshake, char *inputEos, char *outputEos)
tyGSAsynInit("serial1",  "UART0", 0, 19200,'N',1,8,'N',"\n","\n")  /* Oxford IC PLUS E-QUAD */
tyGSAsynInit("serial2",  "UART0", 1, 9600,'N',1,8,'N',"\r","\r")  /* SR630 */
tyGSAsynInit("serial3",  "UART0", 2, 9600,'N',2,8,'N',"\r","\r")  /* Oxford ILM200 */
#tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',1,8,'N',"\r","\r")  /*Keithley 6485 */
#tyGSAsynInit("serial4",  "UART0", 3, 1200,'N',1,8,'N',"\r\n","\r")  /* Acurite */
#tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',1,8,'N',"\r\n","\r")  /* VALCO M6 */
tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',1,8,'N',"\r","\r")  /* VALCO V10 */
tyGSAsynInit("serial5",  "UART0", 4, 9600,'N',1,8,'N',"\r\n","\r")  /* VALCO M6 */
#tyGSAsynInit("serial5",  "UART0", 4, 9600,'N',1,8,'N',"\r\n","\r")  /* */
#tyGSAsynInit("serial6",  "UART0", 5, 9600,'N',1,8,'N',"\r","\r")  /* */
tyGSAsynInit("serial6",  "UART0", 5, 19200,'N',1,8,'Y',"\r","\r")  /* ESP300 */
tyGSAsynInit("serial7",  "UART0", 6, 9600,'N',1,8,'N',"\r","\r")  /* */
#tyGSAsynInit("serial7", "UART0", 6, 9600,'N',1,8,'N',"\r\n","\r")  /* sigmaMeter, test */
tyGSAsynInit("serial8",  "UART0", 7, 9600,'N',2,8,'N',"\r","\r")  /* MKS 937A*/

# GPIB addresses: 1=Tektronix scope, 2=Keithley 2000, 3=Fluke meter
#asynInterposeEosConfig("gpib1", 1, 1, 0)
#asynOctetSetInputEos("gpib1", 1, "\n")
#asynOctetConnect("gpib1:1", "gpib1", 1, 1, 80)
#asynOctetConnect("gpib1:2", "gpib1", 2, 1, 80)
#asynInterposeEosConfig("gpib1", 3, 1, 0)
#asynOctetSetInputEos("gpib1", 3, "\r")
#asynOctetConnect("gpib1:3", "gpib1", 3, 1, 80)

# Debugging
#asynSetTraceMask("gpib1",3,0xff)
#asynSetTraceIOMask("gpib1",3,2)
#asynSetTraceMask("serial3",0,0xff)
#asynSetTraceIOMask("serial3",0,2)
#asynSetTraceMask("serial20",0,0xff)
#asynSetTraceIOMask("serial20",0,2)

# Generic GPIB record
#dbLoadRecords("$(IP)/ipApp/Db/generic_gpib.db", "P=14LAB:,R=gpib2,SIZE=4096,ADDR=3,PORT=gpib1")
#dbLoadRecords("$(CARS)/CARSApp/Db/DG535.db", "P=14LAB:,R=DG1,PORT=gpib1")
#dbLoadRecords("$(CARS)/CARSApp/Db/sigmaMeter.db","P=14LAB:,PORT=serial7")


# Load asynRecord records on all ports
dbLoadTemplate("asynRecord.template")

# Serial 2 has Newport LAE500 Laser Autocollimator
#dbLoadRecords("$(CARS)/CARSApp/Db/LAE500.db", "P=13LAB:,R=LAE500,PORT=serial2")

# Serial 8 Stanford Research Systems SR570 Current Preamplifier
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14LAB:,A=A1,PORT=serial1")

# Serial 8 XIA filter rack
#dbLoadRecords("$(OPTICS)/opticsApp/Db/XIA_shutter.db", "P=13LAB:,S=filter1,ADDRESS=1,PORT=serial8")

# MKS 937A. For testing pumps
dbLoadRecords("$(CARS)/CARSApp/Db/mks937A.db","P=14LAB:,PORT=serial8,CC1=cc1,PR1=pr1,CC=1,PR=4")

# GPIB 3 is Fluke multimeter
#dbLoadRecords("$(CARS)/CARSApp/Db/Fluke_8842A.db", "P=13LAB:,M=Fluke1,PORT=gpib1,A=3")

# Test asyn support of SR630
#dbLoadRecords("$(CARS)/CARSApp/Db/SR630_asyn.db","P=14LAB:,R=SR630,PORT=serial2")
#dbLoadRecords("$(CARS)/CARSApp/Db/oxford_ILM200.db","P=14LAB:,R=ILM,PORT=serial3")
dbLoadRecords("$(CARS)/CARSApp/Db/keithley6485st.db", "P=14LAB:,DEVICE=Keithley1,PORT=serial4,DESC='KEITHLEY1'")
#dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_I1.db", "P=14LAB:,PORT=serial4, ENCODER=VMenc")



