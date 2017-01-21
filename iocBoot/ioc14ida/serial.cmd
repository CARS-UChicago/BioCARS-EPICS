# int tyGSAsynInit(char *port, int uart, int channel, int baud, char parity, int sbits,
#                 int dbits, char handshake, char *inputEos, char *outputEos)
tyGSAsynInit("serial1",  "UART0", 0, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial2",  "UART0", 1, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial3",  "UART0", 2, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial4",  "UART0", 3, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial5",  "UART0", 4, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial6",  "UART0", 5, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial7",  "UART0", 6, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial8",  "UART0", 7, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */

tyGSAsynInit("serial9",  "UART1", 0, 9600,'E',2,7,'N',"\r\n","\002")  /* HEIND281B */
tyGSAsynInit("serial10", "UART1", 1, 9600,'N',2,8,'N',"\r","\r")  /* Mono ILM */
##tyGSAsynInit("serial11", "UART1", 2, 9600,'N',1,8,'N',"\r","\r")  /* SR630 */
tyGSAsynInit("serial11", "UART1", 2, 9600,'N',1,8,'N',"\r\n","\n")  /* SR630 */
tyGSAsynInit("serial12", "UART1", 3, 9600,'N',1,8,'N',"\n","\r")  /* LA2000 */
tyGSAsynInit("serial13", "UART1", 4, 9600,'N',2,8,'N',"\r","\r")  /* MKS 937A */
tyGSAsynInit("serial14", "UART1", 5, 9600,'N',1,8,'N',"\r","\r")  /* MPC */
tyGSAsynInit("serial15", "UART1", 6, 9600,'N',1,8,'N',"\r","\r")  /* MPC */
tyGSAsynInit("serial16", "UART1", 7, 9600,'N',1,8,'N',"\r","\r")  /* MPC */

# Load asynRecord records on all ports
dbLoadTemplate("asynRecord.template")

dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=0,PORT=serial1")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=1,PORT=serial2")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=2,PORT=serial3")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=3,PORT=serial4")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=4,PORT=serial5")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=5,PORT=serial6")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=6,PORT=serial7")
dbLoadRecords("$(CARS)/CARSApp/Db/mks959.db","P=14IDA:,CONT=7,PORT=serial8")


# for Heidenhain 281B encoder
#dbLoadRecords("$(IP)/ipApp/Db/heidND261.db","P=14IDA:,PORT=serial9")
dbLoadRecords("$(CARS)/CARSApp/Db/heindND281B.db","P=14IDA:,PORT=serial9")

# Mono ILM cryo level
dbLoadRecords("$(CARS)/CARSApp/Db/oxford_ILM202.db","P=14IDA:,R=ILM,PORT=serial10")

# SR630 Thermal Couple Reader

dbLoadRecords("$(IP)/ipApp/Db/SR630.db","P=14IDA:,R=SR630,PORT=serial11")
##dbLoadTemplate("SR630.template")
##IK
dbLoadRecords("$(ASYN)/db/asynRecord.db", "P=14IDA:, R=asyn11, PORT=serial11, ADDR=0, IMAX=80, OMAX=80")

# LA2000
#dbLoadRecords("$(CARS)/CARSApp/Db/LA2000.db","P=14IDA:,R=LA2000,PORT=serial12")
dbLoadRecords("$(CARS)/CARSApp/Db/LA2000_IKseq.db","P=14IDA:,R=LA2000,PORT=serial12")

dbLoadRecords("$(CARS)/CARSApp/Db/mks937A.db","P=14IDA:,PORT=serial13,CC1=HLS_cc1,PR1=HLS_pr1,CC=1,PR=4")

# PI MPC ion pump
# Disabled on 11/18/10 because crate is locking up periodically
#dbLoadRecords("$(IP)/ipApp/Db/MPC.db","P=14IDA:,PUMP=ip2,PORT=serial14,PA=1,PN=1")
#dbLoadRecords("$(IP)/ipApp/Db/MPC.db","P=14IDA:,PUMP=ip3,PORT=serial14,PA=1,PN=2")
#dbLoadRecords("$(IP)/ipApp/Db/MPC.db","P=14IDA:,PUMP=ip4,PORT=serial15,PA=1,PN=1")
#dbLoadRecords("$(IP)/ipApp/Db/MPC.db","P=14IDA:,PUMP=ip5,PORT=serial15,PA=1,PN=2")
#dbLoadRecords("$(IP)/ipApp/Db/MPC.db","P=14IDA:,PUMP=ip6,PORT=serial16,PA=1,PN=1")
#dbLoadRecords("$(IP)/ipApp/Db/MPC.db","P=14IDA:,PUMP=ip7,PORT=serial16,PA=1,PN=2")

