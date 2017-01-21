ipacAddVIPC616_01("0x2000,0xa0000000")

#ipacAddTVME200("201FA0")

ipacReport(2)

tyGSOctalDrv 2

tyGSOctalModuleInit("UART0","GSIP_OCTAL232", 0x80, 0, 0)
tyGSOctalModuleInit("UART1","GSIP_OCTAL232", 0x81, 0, 2)

# Initialize Systran DAC
# initDAC128V(char *portName, int carrier, int slot)
# portName  = name to give this asyn port
# carrier     = IPAC carrier number (0, 1, etc.)
# slot        = IPAC slot (0,1,2,3, etc.)
#initDAC128V("DAC1", 0, 3)
#initDAC128V("DAC1", 0, 1)
#dbLoadTemplate "14IDA.DAC.template"



