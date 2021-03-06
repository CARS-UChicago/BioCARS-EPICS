#< alio.cmd

# Pseudo vertical and horizontal motion of the ALIO
dbLoadRecords("$(CARS)/CARSApp/Db/SampleYZ_IDB.db","P=14IDB:,X=m152,Y=m153,PHI=m151")

strcpy(str2,"P=14IDB:,D=alio1,PORT=pmacAliog,PHI=2,X=3,Y=4,Z=1,AIR=M115,AIRT=P907,")
strcat(str2,"XYDAC=P810,PHS=P1011,PHPLC=2,PPLC=10,PS=P910,HPLC=11,HS=P920,APC=0,")
strcat(str2,"AE=P20,APCS=1,AMIPP=500,ACIPP=500,P250=P250,P251=P251,P252=P252,P255=P255,P256=P256,P257=P257,")
strcat(str2,"P258=P258,P259=P259,P260=P260,P261=P261,P262=P262,P263=P263,P264=P264,I=14IDB:Is,E=14IDB:Exphi")
seq &aliogFSMs_BioCARS, str2
