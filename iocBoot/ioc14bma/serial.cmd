# int tyGSAsynInit(char *port, int uart, int channel, int baud, char parity, int sbits,
#                 int dbits, char handshake, char *inputEos, char *outputEos)
tyGSAsynInit("serial1",  "UART0", 0, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 GOal Post */
tyGSAsynInit("serial2",  "UART0", 1, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Outboard EA */
tyGSAsynInit("serial3",  "UART0", 2, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Inboard EA */
tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 Diag Package */
tyGSAsynInit("serial5",  "UART0", 4, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570 14BMD Mono diode*/
tyGSAsynInit("serial6",  "UART0", 5, 9600,'N',2,8,'N',"\r","\r")  /* SRS 570  White beam Intensity Monitor*/
tyGSAsynInit("serial7",  "UART0", 6, 9600,'N',1,8,'N',"\r","\r")  /* */
tyGSAsynInit("serial8",  "UART0", 7, 9600,'E',1,8,'N',"\r","\r")  /* MKS 937 */

dbLoadRecords("$(CARS)/CARSApp/Db/BMApresTemp.db", "P=14BMA")

# Load asynRecord records on all ports
dbLoadTemplate("asynRecord.template")

# Serial 1-6 Stanford Research Systems SR570 Current Preamplifier
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMA:,A=A1,PORT=serial1")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMA:,A=A2,PORT=serial2")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMA:,A=A3,PORT=serial3")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMA:,A=A4,PORT=serial4")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMA:,A=A5,PORT=serial5")
dbLoadRecords("$(IP)/ipApp/Db/SR570.db", "P=14BMA:,A=A6,PORT=serial6")
dbLoadRecords("$(IP)/ipApp/Db/MKS.db", "P=14BMA:,PORT=serial8,CC1=cc1,CC2=cc2,PR1=pr1,PR2=pr2")

# compute x-ray energy
dbLoadRecords("$(CARS)/CARSApp/Db/BM14_Energy.db","P=14BMA:")




