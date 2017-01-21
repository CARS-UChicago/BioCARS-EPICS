ipacAddVIPC616_01("0x2000,0xa0000000")
#ipacAddVIPC616_01("0x3400,0xa2000000")

ipacReport(2)

# gsIP488Configure(char *portName, int carrier, int module, int vector,
#                  unsigned int priority, int noAutoConnect)
#NL gsIP488Configure("gpib1",0,2,0x69,0,0) 
    
tyGSOctalDrv 1
tyGSOctalModuleInit("UART0","GSIP_OCTAL232", 0x80, 0, 0)
#tyGSOctalModuleInit("GSIP_OCTAL232", 0x81, 1, 2)


