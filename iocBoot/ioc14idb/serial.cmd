# int tyGSAsynInit(char *port, int uart, int channel, int baud, char parity, int sbits,
#                 int dbits, char handshake, char *inputEos, char *outputEos)
tyGSAsynInit("serial1",  "UART0", 0, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Ion Chamber 1 */
tyGSAsynInit("serial2",  "UART0", 1, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Table Diode */
tyGSAsynInit("serial3",  "UART0", 2, 9600,'N',2,8,'N',"\r\n","\r")  /* VALCO M6 */
tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',2,8,'N',"\r","\r")  /* MKS 937A */
tyGSAsynInit("serial5",  "UART0", 4,19200,'N',1,8,'Y',"\r","\r")  /* ESP300 */
tyGSAsynInit("serial6",  "UART0", 5, 9600,'N',2,8,'N',"\r","\r")  /* ILM cryo level */
tyGSAsynInit("serial7",  "UART0", 6, 9600,'N',1,8,'N',"\r","\r")  /* oxford cryo controller*/
tyGSAsynInit("serial8",  "UART0", 7,19200,'N',1,8,'N',"\r","\r")  /* MCB4B */

tyGSAsynInit("serial9",  "UART1", 0, 9600,'N',1,8,'N',"\r","\r")  /* Kiethley 1 */
tyGSAsynInit("serial10", "UART1", 1, 9600,'N',1,8,'N',"\r","\r")  /* Kiethley 2 */
tyGSAsynInit("serial11", "UART1", 2, 9600,'N',1,8,'N',"\r","\r")  /*  */
#####tyGSAsynInit("serial11",  "UART1", 2,19200,'N',1,8,'Y',"\r","\r")  /* ESP301 Linda Young, 1 */
#####tyGSAsynInit("serial12",  "UART1", 3,19200,'N',1,8,'Y',"\r","\r")  /* ESP301 Linda Young, 2 */
tyGSAsynInit("serial12", "UART1", 3, 9600,'N',1,8,'N',"\r","\r")  /*  */
tyGSAsynInit("serial13", "UART1", 4, 9600,'N',2,8,'N',"\r","\r")  /* VALCO V10 */
tyGSAsynInit("serial14", "UART1", 5, 9600,'N',1,8,'N',"\n","")    /* GentecDuo */
tyGSAsynInit("serial15", "UART1", 6, 9600,'N',1,8,'N',"\r\n","\r")  /* sigmaMeter */
tyGSAsynInit("serial16", "UART1", 7, 9600,'O',1,7,'N',"\r","\r")  /* Syringe Pump */


# Keithley 2701
drvAsynIPPortConfigure("serial17","164.54.161.14:1394",0,0,0)

dbLoadRecords("$(IP)/ipApp/Db/Keithley2kDMM_mf.db","P=14Keithley1:,Dmm=DMM1,PORT=serial17")

# Load asynRecord records on all ports
dbLoadTemplate("asynRecord.template")

# Serial 1-4 Stanford Research Systems SR570 Current Preamplifier
#dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14IDB:,A=A1,PORT=serial1")
#dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14IDB:,A=A2,PORT=serial2")
#dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14IDB:,A=A3,PORT=serial3")

dbLoadRecords("$(CARS)/CARSApp/Db/mks937A.db","P=14IDB:,PORT=serial4,CC1=IDB_cc1,PR1=IDB_pr1,CC=1,PR=4")

dbLoadRecords("$(CARS)/CARSApp/Db/oxford_ILM200.db","P=14IDB:,R=ILM,PORT=serial6")
#dbLoadRecords("$(CARS)/CARSApp/Db/oxfordCryoRead.db","P=14IDB:,PORT=serial7")
############dbLoadRecords("$(CARS)/CARSApp/Db/oxfordCryoRead_Stream.db","P=14IDB:,PORT=serial7") 
dbLoadRecords("$(STD)/stdApp/Db/pvHistory.db","P=14IDB:,N=Cryo,MAXSAMPLES=1440")

#dbLoadRecords("$(CARS)/CARSApp/Db/gentecDuo.db","P=14IDB:,PORT=serial14")
dbLoadRecords("$(CARS)/CARSApp/Db/sigmaMeter.db","P=14IDB:,PORT=serial15")
dbLoadRecords("$(CARS)/CARSApp/Db/keithley6485st.db", "P=14IDB:,DEVICE=Keithley1,PORT=serial9,DESC='KEITHLEY1'")
dbLoadRecords("$(CARS)/CARSApp/Db/keithley6485st.db", "P=14IDB:,DEVICE=Keithley2,PORT=serial10,DESC='KEITHLEY2'")
#dbLoadRecords("$(CARS)/CARSApp/Db/keithley6485st.db", "P=14IDB:,DEVICE=Keithley3,PORT=serial11,DESC='KEITHLEY3'")

# Serial 4 MCB4B motor controller
# MCB-4B driver setup parameters:
#     (1) maximum # of controllers,
#     (2) motor task polling rate (min=1Hz, max=60Hz)
MCB4BSetup(1, 10)

# MCB-4B driver configuration parameters:
#     (1) controller
#     (2) asyn port name (e.g. serial1)
MCB4BConfig(0, "serial8")

dbLoadRecords("$(DELAYGEN)/delaygenApp/Db/devDG535.db","P=14IDB:,R=DG535_1,L=0,A=1")
dbLoadRecords("$(DELAYGEN)/delaygenApp/Db/devDG535.db","P=14IDB:,R=DG535_2,L=0,A=2")

# FPGA- commented out for testing IK 9-24-09
#
drvAsynIPPortConfigure("serial18", "164.54.161.85:2000 HTTP", 0, 0, 0)
asynOctetSetOutputEos("serial18",0,"\r")
asynOctetSetInputEos("serial18",0,"\n")
drvAsynIPPortConfigure("serial20", "164.54.161.119:2000 HTTP", 0, 0, 0)
asynOctetSetOutputEos("serial20",0,"\r")
asynOctetSetInputEos("serial20",0,"\n")
dbLoadRecords("$(CARS)/CARSApp/Db/fpga.db","P=14IDB:,F=fpga")

# Digital logger power switch
drvAsynIPPortConfigure("serial19", "164.54.161.16:80 HTTP", 0, 1, 0)
#asynOctetSetOutputEos("serial18",0,"\r")
#asynOctetSetInputEos("serial18",0,"\n")
dbLoadRecords("$(DLIEPCR)/dliEpcrApp/Db/dliEpcr.db","P=14IDB:,D=Dliepcr1,DESC=Dliepcr1")
