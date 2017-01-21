# int tyGSAsynInit(char *port, int uart, int channel, int baud, char parity, int sbits,
#                 int dbits, char handshake, char *inputEos, char *outputEos)
tyGSAsynInit("serial1",  "UART0", 0, 1200,'N',1,8,'N',"\r\n","\r")  /* Acurite */
tyGSAsynInit("serial2",  "UART0", 1, 1200,'N',1,8,'N',"\r\n","\r")  /* Acurite */
tyGSAsynInit("serial3",  "UART0", 2, 1200,'N',1,8,'N',"\r\n","\r")  /* Acurite */
tyGSAsynInit("serial4",  "UART0", 3, 19200,'N',1,8,'N',"\n","\n")  /* Oxford-Danfysik IC PLUS QBPM */
tyGSAsynInit("serial5",  "UART0", 4, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial6",  "UART0", 5, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial7",  "UART0", 6, 9600,'N',1,8,'N',"FF","FF")  /* MKS 959 */
tyGSAsynInit("serial8",  "UART0", 7, 9600,'E',1,8,'N',"FF","FF")  /* MKS 959 */

# Load asynRecord records on all ports
dbLoadTemplate("asynRecord.template")

#dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_biocars.db","P=14IDC:,PORT=serial1,ENCODER=VMenc")
#dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_biocars.db","P=14IDC:,PORT=serial2,ENCODER=HMenc")
#dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_biocars.db","P=14IDC:,PORT=serial3,ENCODER=PBSenc")
dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_I.db","P=14IDC:,PORT=serial1,ENCODER=VMenc")
dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_I.db","P=14IDC:,PORT=serial2,ENCODER=HMenc")
dbLoadRecords("$(CARS)/CARSApp/Db/AcuriteDRO_I.db","P=14IDC:,PORT=serial3,ENCODER=PBSenc")
#dbLoadRecords("$(CARS)/CARSApp/Db/oxford-dqm.db","P=14IDC:,DEVICE=BPM1,PORT=serial4,AD=0,AVGCURRSUMCNT=10,DESCR='14IDC-BPM'")
 

