program gentecDuo("P=14IDB:")
/*
*
*	Program to read out Gentec Laser Power meter. To be used with database 
*	gentecDuo.db. Seems to work best at 9600 Baud. Increasing 
*	the speed to 19200 seemed to cause problems. Use gentecDuo.db as a
*	database file for this program.
*	Timothy Graber 3/16/03 
*
*
*/

%% #include <string.h>
//%% #include "vxWorks.h"
//%% #include "taskLib.h"
//%% #include "sysLib.h"
%% #include "epicsTime.h"
%% #include <time.h>
%% #include <math.h>
%% #include <errlog.h>

#define NO_TIMEOUT 10   

/* This program must be compiled with the recursive option */
option +r;

#define Debug(L,FMT,V...) {  if(L <= debugLevel) \
                        { printf(FMT,##V); } }

#define CDebug(L,FMT,V...) {  if(L <= pVar->debugLevel) \
                        { printf(FMT,##V); } }


/* Define PVs */
int   debugLevel;             
assign debugLevel  to "{P}gentecDebugLevel.VAL";
monitor debugLevel;

string  gentecOut;
assign gentecOut    to "{P}gentecSer.AOUT";
monitor gentecOut;

string  gentecIn;    
assign gentecIn    to "{P}gentecSer.AINP";
monitor gentecIn;

string  gentecRW;    
assign gentecRW    to "{P}gentecSer.TMOD";
monitor gentecRW;

int gentecPROC;    
assign gentecPROC    to "{P}gentecSer.PROC";
monitor gentecPROC;

string  unitsA;    
assign unitsA    to "{P}gentecUnitsA.VAL";

string  headA;    
assign headA    to "{P}gentecHeadA.VAL";

string  sensA;    
assign sensA    to "{P}gentecSensA.VAL";

string  respTmA;    
assign respTmA    to "{P}gentecRespTmA.VAL";

float gentecPwrA;
assign gentecPwrA to "{P}gentecPwrA.VAL";

string  unitsB;    
assign unitsB    to "{P}gentecUnitsB.VAL";

string  headB;    
assign headB    to "{P}gentecHeadB.VAL";

string  sensB;    
assign sensB    to "{P}gentecSensB.VAL";

string  respTmB;    
assign respTmB    to "{P}gentecRespTmB.VAL";

float gentecPwrB;
assign gentecPwrB to "{P}gentecPwrB.VAL";

int   gentecInTO;              
assign gentecInTO   to "{P}gentecSer.TMOT";
monitor gentecInTO;


int update;
assign update to "{P}gentecUpdate.PROC";
monitor update;

evflag updateMon; sync update updateMon;
evflag gentecInMon; sync gentecIn gentecInMon;

int gentecInIndex;
int gentecOutIndex;
int gentecRWIndex;
int gentecPROCIndex;
int gentecInTOIndex;
%{
void Read(SS_ID ssId, struct UserVar *pVar, int timeOut);
void WriteRead(SS_ID ssId, struct UserVar *pVar, char *cmdstr, int timeOut);
void gentecGet(SS_ID ssId, struct UserVar *pVar, char *cmdstr);
}%


ss gentecDuo {
    /* Initialize things when first starting */
    state init {
        when() {
            gentecInTOIndex = pvIndex(gentecInTO);
            gentecRWIndex = pvIndex(gentecRW);
            gentecInIndex = pvIndex(gentecIn);
            gentecPROCIndex = pvIndex(gentecPROC);
            gentecOutIndex = pvIndex(gentecOut);
	    efClear(updateMon);
	    efClear(gentecInMon);
	    
%%    	    gentecGet(ssId, pVar, "*HEA");
	    strcpy(headA, gentecIn);
	    pvPut(headA,SYNC);
	
%%    	    gentecGet(ssId, pVar, "*RTA");
	    strcpy(respTmA, gentecIn);
	    pvPut(respTmA,SYNC);
	
%%    	    gentecGet(ssId, pVar, "*SNA");
	    strcpy(sensA, gentecIn);
	    pvPut(sensA,SYNC);
	    
%%    	    gentecGet(ssId, pVar, "*HEB");
	    strcpy(headB, gentecIn);
	    pvPut(headB,SYNC);
	
%%    	    gentecGet(ssId, pVar, "*RTB");
	    strcpy(respTmB, gentecIn);
	    pvPut(respTmB,SYNC);
	
%%    	    gentecGet(ssId, pVar, "*SNB");
	    strcpy(sensB, gentecIn);
	    pvPut(sensB,SYNC);
        } state monitor_inputs
    }  /* End state init */

    state monitor_inputs {
      when(efTestAndClear(updateMon)) {

%%	gentecGet(ssId, pVar, "*SAA");
 	sscanf(gentecIn,"%*3c%f%s", &gentecPwrA, unitsA);
	pvPut(gentecPwrA,SYNC);
	pvPut(unitsA,SYNC);
	
 %%	gentecGet(ssId, pVar, "*SAB");
 	sscanf(gentecIn,"%*3c%f%s", &gentecPwrB, unitsB);
	pvPut(gentecPwrB,SYNC);
	pvPut(unitsB,SYNC);
	
	Debug(2, "\n");
     } state monitor_inputs
   } 
} /* End ss gentecDuo */

%{
void gentecGet(SS_ID ssId, struct UserVar *pVar, char *cmdstr)
{
    	WriteRead(ssId, pVar, cmdstr, NO_TIMEOUT );
   	Read(ssId, pVar, NO_TIMEOUT); /* Data comes next */
}

void WriteRead(SS_ID ssId, struct UserVar *pVar, char *cmdstr, int timeOut)
{	
	int i, nloops, nchar;
     	strcpy(pVar->gentecRW, "Write/Read");
	seq_pvPut(ssId, pVar->gentecRWIndex, 0);
	strcpy(pVar->gentecOut , cmdstr);
	seq_efClear(ssId, gentecInMon);
	seq_pvPut(ssId, pVar->gentecOutIndex, 0);
    	CDebug(5, "writeGentec: %s\n", cmdstr); 	
  	pVar->gentecInTO = timeOut;
	seq_pvPut(ssId, pVar->gentecInTOIndex, 0);
//   	nloops = pVar->gentecInTO*sysClkRateGet()/1000;
	nloops = 20;
    	for (i=0; i<nloops; i++) {
  		seq_pvGet(ssId, pVar->gentecInIndex, 0);
      		if (pVar->gentecIn[0] == 13) break;
        	epicsThreadSleep(.05);
    	}
    	CDebug(5, "readGentec: timeOut=%d, nloops=%d, loops used=%d\n", timeOut, nloops, i); 	
 	CDebug(2, "readGentec: gentecIn = \"%d\"\n", pVar->gentecIn[0]); 	
 			 
}

void Read(SS_ID ssId, struct UserVar *pVar, int timeOut)
{
	int i, nloops, nchar;
      	strcpy(pVar->gentecRW, "Read");
	seq_pvPut(ssId, pVar->gentecRWIndex, 0);
	seq_efClear(ssId, gentecInMon);
 	pVar->gentecInTO = timeOut;
	seq_pvPut(ssId, pVar->gentecInTOIndex, 0);
	seq_pvGet(ssId, pVar->gentecPROCIndex, 0);
 	pVar->gentecPROC=1-pVar->gentecPROC;
    	CDebug(5, "readGentec: PROC=%d\n", pVar->gentecPROC); 	
 	seq_pvPut(ssId, pVar->gentecPROCIndex, 0);
//   	nloops = pVar->gentecInTO*sysClkRateGet()/1000;
	nloops = 20;
    	for (i=0; i<nloops; i++) {
        	if (seq_efTestAndClear(ssId, gentecInMon)) break;
        	epicsThreadSleep(.05);
    	}
	seq_pvGet(ssId, pVar->gentecInIndex, 0);
	nchar = strlen(pVar->gentecIn);
    	CDebug(5, "readGentec: timeOut=%d, nloops=%d, loops used=%d\n", timeOut, nloops, i); 	
 	for (i=0; i<nchar; i++) 
		if (pVar->gentecIn[i] == 13) pVar->gentecIn[i] = '\0';
 	CDebug(2, "readGentec: gentecIn = \"%s\",   nChar = %d\n", pVar->gentecIn, nchar); 	

}
}%
