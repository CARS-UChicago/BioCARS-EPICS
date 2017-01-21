program sigmaMeter("P=14IDB:")
/*
*
*	Program to read out sigmaMeter Laser Power meter. To be used with database 
*	sigmaMeterDuo.db. Seems to work best at 9600 Baud. Increasing 
*	the speed to 19200 seemed to cause problems. Use sigmaMeterDuo.db as a
*	database file for this program.
*	Timothy Graber 3/16/03 
*
*
*/

%% #include <string.h>
%% #include "epicsTime.h"
%% #include <time.h>
%% #include <math.h>
%% #include <errlog.h>
%% #include <stdlib.h>

#define NO_TIMEOUT 10  


/* This program must be compiled with the recursive option */
option +r;

#define Debug(L,FMT,V...) {  if(L <= debugLevel) \
                        { printf(FMT,##V); } }

#define CDebug(L,FMT,V...) {  if(L <= pVar->debugLevel) \
                        { printf(FMT,##V); } }


/* Define PVs */
int   debugLevel;             
assign debugLevel  to "{P}sigmaMeterDebugLevel.VAL";
monitor debugLevel;

string  sigmaMeterOut;
assign sigmaMeterOut    to "{P}sigmaMeterSer.AOUT";
monitor sigmaMeterOut;

int sigmaMeterProc;
assign sigmaMeterProc    to "{P}sigmaMeterSer.PROC";
monitor sigmaMeterProc;

char  sigmaMeterIn[200]; 
assign sigmaMeterIn    to "{P}sigmaMeterSer.BINP";
monitor sigmaMeterIn;
evflag sigmaMeterInMon; 
sync sigmaMeterIn sigmaMeterInMon;

double   sigmaMeterInTO;              
assign sigmaMeterInTO   to "{P}sigmaMeterSer.TMOT";
monitor sigmaMeterInTO;

string   sigmaMeterIEOS;              
assign sigmaMeterIEOS   to "{P}sigmaMeterSer.IEOS";
monitor sigmaMeterIEOS;

string  sigmaMeterRW;    
assign sigmaMeterRW    to "{P}sigmaMeterSer.TMOD";
monitor sigmaMeterRW;

string  calDate;    
assign calDate    to "{P}sigmaMeterCalDate.VAL";

string  model;    
assign model    to "{P}sigmaMeterModel.VAL";

string  temperature;    
assign temperature    to "{P}sigmaMeterTemperature.VAL";

string  type;    
assign type    to "{P}sigmaMeterType.VAL";


double   sigmaMeterAve;              
assign sigmaMeterAve   to "{P}sigmaMeterAve.VAL";
monitor sigmaMeterAve;

double   sigmaMeterDev;              
assign sigmaMeterDev   to "{P}sigmaMeterDev.VAL";
monitor sigmaMeterDev;

double   sigmaMeterMin;              
assign sigmaMeterMin   to "{P}sigmaMeterMin.VAL";
monitor sigmaMeterMin;

double   sigmaMeterMax;              
assign sigmaMeterMax   to "{P}sigmaMeterMax.VAL";
monitor sigmaMeterMax;

double   sigmaMeterHz;              
assign sigmaMeterHz   to "{P}sigmaMeterHz.VAL";
monitor sigmaMeterHz;

double   sigmaMeterPri;              
assign sigmaMeterPri   to "{P}sigmaMeterPri.VAL";
monitor sigmaMeterPri;

double   sigmaMeterPer;              
assign sigmaMeterPer   to "{P}sigmaMeterPer.VAL";
monitor sigmaMeterPer;

string  confFunc;
assign confFunc    to "{P}sigmaMeterConfFunc.VAL";
monitor confFunc;

string  confRang;
assign confRang    to "{P}sigmaMeterConfRang.VAL";
monitor confRang;

string  sigmaMeterOVR;
assign sigmaMeterOVR    to "{P}sigmaMeterOvr.VAL";

int setRang;
assign setRang to "{P}sigmaMeterSetRang";
monitor setRang;
evflag setRangMon; 
sync setRang setRangMon;

string statOnOff;
assign statOnOff to "{P}sigmaMeterStatOnOff";
monitor statOnOff;
evflag statOnOffMon; 
sync statOnOff statOnOffMon;

int update;
assign update to "{P}sigmaMeterUpdate.PROC";
monitor update;
evflag updateMon; 
sync update updateMon;

double   statBatSiz;              
assign statBatSiz   to "{P}sigmaMeterStatBatSiz.VAL";
monitor statBatSiz;
evflag statBatSizMon; 
sync statBatSiz statBatSizMon;

int statStart;
assign statStart to "{P}sigmaMeterStatStart";
monitor statStart;
evflag statStartMon; 
sync statStart statStartMon;

int refresh;
assign refresh to "{P}sigmaMeterRefresh";
monitor refresh;
evflag refreshMon; 
sync refresh refreshMon;

char buff[200];
char vals[4][100];
char statModeVal[3];
string Rang; string Rang2;

%%char char_buff;
%%int i, j, k, l, nrec;
double intTime;
int sigmaMeterProcIndex;
int sigmaMeterIEOSIndex;
int sigmaMeterInIndex;
int sigmaMeterOutIndex;
int sigmaMeterRWIndex;
int sigmaMeterInTOIndex;
unsigned int statusFlag;

#define MAX(a,b) ((a)>(b)? (a): (b))
#define MIN(a,b) ((a)<(b)? (a): (b))

/* comment IK for all functions defined as C-code I removed %% in the body of the ss code -test it */

/* also made modifications in sigmmeterWait replacing pVar->... just by variable will it work?? */
%{
	void sigmaMeterWR(SS_ID ssId, struct UserVar *pVar, char *cmdStr, EV_ID sigmaMeterInMon);
	void sigmaMeterW(SS_ID ssId, struct UserVar *pVar, char *cmdStr);
	void sigmaMeterR(SS_ID ssId, struct UserVar *pVar, EV_ID sigmaMeterInMon);
	void sigmaMeterWait(SS_ID ssId, struct UserVar *pVar, double timeOut, EV_ID sigmaMeterInMon);
        static void efClear_sigmaMon(SS_ID ssId,  EV_ID sigmaMeterInMon);
}%


ss sigmaMeter{
 
	state init {
		when() {
		} state refresh 
	} 

	state refresh {
        when() {
            sigmaMeterProcIndex = pvIndex(sigmaMeterProc);
			sigmaMeterIEOSIndex = pvIndex(sigmaMeterIEOS);
   
            sigmaMeterInTOIndex = pvIndex(sigmaMeterInTO);
            sigmaMeterRWIndex = pvIndex(sigmaMeterRW);
            sigmaMeterInIndex = pvIndex(sigmaMeterIn);
            sigmaMeterOutIndex = pvIndex(sigmaMeterOut);
	        efClear(updateMon);
	        efClear(sigmaMeterInMon);
		efClear(statOnOffMon);
		efClear(setRangMon);
%%    		sigmaMeterW(ssId, pVar, "*RST");
%%        	epicsThreadSleep(5.);	        
    	    sigmaMeterWR(ssId, pVar, "SYST:COMM:SER:SERV OFF",  sigmaMeterInMon);

%%    		sigmaMeterW(ssId, pVar, "CONF:READ:HEAD OFF");
%%    		sigmaMeterW(ssId, pVar, "CONF:READ:SEND PRI,HZ,PER,FLAG");

    		sigmaMeterWR(ssId, pVar, "CONF:STAT:BAT:TIME?",  sigmaMeterInMon);
 			statBatSiz =atof(sigmaMeterIn);
			pvPut(statBatSiz, 2);

    		sigmaMeterWR(ssId, pVar, "CONF:STAT:MODE?",  sigmaMeterInMon);
 	        if (!strcmp(sigmaMeterIn,"ON")) 
 				strcpy(statOnOff,"Off");
 	        else 
 				strcpy(statOnOff,"On");
			pvPut(statOnOff, 2);			
				    
    	    sigmaMeterWR(ssId, pVar, "SYST:INFO:PROB:TYPE?",  sigmaMeterInMon);
	        strcpy(type, sigmaMeterIn);
			pvPut(type,SYNC);
	
    		sigmaMeterWR(ssId, pVar, "SYST:INFO:PROB:MODEL?",  sigmaMeterInMon);
			strcpy(model, sigmaMeterIn);
			pvPut(model,SYNC);
	
    		sigmaMeterWR(ssId, pVar, "SYST:INFO:PROB:TEMP?",  sigmaMeterInMon);
			strcpy(temperature, sigmaMeterIn);
			pvPut(temperature,SYNC);
	    
    		sigmaMeterWR(ssId, pVar, "SYST:INFO:PROB:CALD?",  sigmaMeterInMon);
			strcpy(calDate, sigmaMeterIn);
			pvPut(calDate,SYNC);

    		sigmaMeterWR(ssId, pVar, "CONF:FUNC?",  sigmaMeterInMon);
 	        strcpy(confFunc, sigmaMeterIn);
			pvPut(confFunc, 2);

    		sigmaMeterWR(ssId, pVar, "CONF:RANG:SEL?",  sigmaMeterInMon);
 	        strcpy(confRang, sigmaMeterIn);
			pvPut(confRang, 2);

			sigmaMeterPer = 0.05;

		} state monitor_inputs
	}
	
    state monitor_inputs {
    
		when(efTestAndClear(statOnOffMon)) {
			if (!strcmp(statOnOff,"On")) 
%%    			sigmaMeterW(ssId, pVar, "CONF:STAT:MODE ON");
			else
%%    			sigmaMeterW(ssId, pVar, "CONF:STAT:MODE OFF");
		} state monitor_inputs
   
		when(efTestAndClear(statBatSizMon)) {
			sprintf(buff,"CONF:STAT:BAT:TIME %f", statBatSiz);
%%    		sigmaMeterW(ssId, pVar, pVar->buff);
		} state monitor_inputs
		
		when(efTestAndClear(statStartMon)& (statStart == 1)) {
			efSet(updateMon);
		} state monitor_inputs
 
 		when(efTestAndClear(refreshMon) & (refresh == 1)) {
 			refresh = 0;
 			pvPut(refresh);
 			
		} state refresh
		
		when(efTestAndClear(setRangMon)) {
			if (setRang == 0) strcpy(Rang,"3.000E-02");
			if (setRang == 1) strcpy(Rang,"3.000E-03");
			if (setRang == 2) strcpy(Rang,"3.000E-04");
			if (setRang == 3) strcpy(Rang,"3.000E-05");
			if (setRang == 4) strcpy(Rang,"3.000E-06");
			strcpy(Rang2, "CONF:RANG:SEL ");
			strcat(Rang2, Rang);
%%			sigmaMeterW(ssId,pVar, pVar->Rang2);
%%			sigmaMeterW(ssId,pVar, "CONF:RANG:SEL?");
			sigmaMeterR(ssId,pVar,  sigmaMeterInMon);
	 	        strcpy(confRang, sigmaMeterIn);
			pvPut(confRang, 2);
		} state monitor_inputs

   		when(efTestAndClear(updateMon)) {
			intTime = 10.*sigmaMeterPer;
    		sigmaMeterWR(ssId, pVar, "CONF:FUNC?",  sigmaMeterInMon);
 	        strcpy(confFunc, sigmaMeterIn);
			pvPut(confFunc, 2);
			
    		sigmaMeterWR(ssId, pVar, "CONF:STAT:MODE?",  sigmaMeterInMon);
			strcpy(statModeVal,sigmaMeterIn);
%%			nrec=0;

			if (!strcmp(statModeVal,"ON")) 	{
%%    			sigmaMeterW(ssId, pVar, "SYST:COMM:SER:SERV ON");
%%    			sigmaMeterW(ssId, pVar, "INIT");
%%    			sigmaMeterW(ssId, pVar, "CONF:STAT:START");
/*    			sigmaMeterWait(ssId, pVar, pVar->statBatSiz, sigmaMeterInMon); */
			sigmaMeterWait(ssId, pVar, statBatSiz, sigmaMeterInMon);
%%    			sigmaMeterW(ssId, pVar, "ABOR");
%%    			sigmaMeterW(ssId, pVar, "SYST:COMM:SER:SERV OFF");
    			sigmaMeterWR(ssId, pVar, "FETC:NREC?",  sigmaMeterInMon);
  				strcpy(buff,sigmaMeterIn);
%%  			nrec=atoi(pVar->buff);
			if (nrec==0) {
				strcpy(sigmaMeterOVR,"No triggers");
				pvPut(sigmaMeterOVR);
			}
%%    			sigmaMeterW(ssId, pVar, "FETC:ALL?");
			}
			else {
%%    			sigmaMeterW(ssId, pVar, "SYST:COMM:SER:SERV ON");
%%    			sigmaMeterW(ssId, pVar, "INIT");
/* IK    			sigmaMeterWait(ssId, pVar, pVar->statBatSiz,sigmaMeterInMon); */

			sigmaMeterWait(ssId, pVar, statBatSiz,sigmaMeterInMon);
%%    			sigmaMeterW(ssId, pVar, "ABOR");
%%    			sigmaMeterW(ssId, pVar, "SYST:COMM:SER:SERV OFF");
    			sigmaMeterWR(ssId, pVar, "FETC:NREC?", sigmaMeterInMon);
  				strcpy(buff,sigmaMeterIn);
%%  			nrec=atoi(pVar->buff);
			if (nrec==0) {
				strcpy(sigmaMeterOVR,"No triggers");
				pvPut(sigmaMeterOVR);
			}
%%    			sigmaMeterW(ssId, pVar, "FETC:ALL?");
			}

			Debug(2, "sigmaMeter: nrec=%d\n", nrec);
%%			for (l=0; l<nrec; l++) {
   			sigmaMeterR(ssId, pVar,  sigmaMeterInMon);
  				strcpy(buff,sigmaMeterIn);
 %{	
				i=0;
				k=0;
				j=0;
				do {
					char_buff=pVar->buff[k];
					pVar->vals[j][i]=char_buff;	
					if (char_buff == ',' || char_buff == '\0') {
							pVar->vals[j][i]='\0';
							j++;
							i=0;
					}
					else
						i++;
					if (char_buff == '\0') break;
		            k++;
	            } while (j<4);
}%				
  				if (!strcmp(statModeVal,"ON")) {
					Debug(2,"sigmaMeter:STAT:MODE:ON: AVE=%s, DEV=%s, MIN=%s, MAX=%s\n", vals[0], vals[1], vals[2], vals[3]);
       
					if (vals[0]=="O") printf("%s\n",vals[0]);
    					sigmaMeterAve=atof(vals[0]);
   					sigmaMeterDev=atof(vals[1]);
   					sigmaMeterMin=atof(vals[2]);
   					sigmaMeterMax=atof(vals[3]);
					if (!strcmp(vals[0],"OVR")) {
						strcpy(sigmaMeterOVR,"OVR");
						pvPut(sigmaMeterOVR);
					}
					else
					{
						strcpy(sigmaMeterOVR,"");
						pvPut(sigmaMeterOVR);
					}

					pvPut(sigmaMeterAve, 2);
					pvPut(sigmaMeterDev, 2);
					pvPut(sigmaMeterMin, 2);
					pvPut(sigmaMeterMax, 2);
				}
				else if (!strcmp(statModeVal,"OFF")) {
					Debug(2,"sigmaMeter:STAT:MODE:OFF PRI=%s, HZ=%s, PER=%s, FLAG=%s\n", vals[0], vals[1], vals[2], vals[3]);
					if (!strcmp(vals[0],"OVR")) {
						strcpy(sigmaMeterOVR,"OVR");
						pvPut(sigmaMeterOVR);
					}
					else
					{
						strcpy(sigmaMeterOVR,"");
						pvPut(sigmaMeterOVR);
					}
						
					sigmaMeterPri=atof(vals[0]);
					sigmaMeterHz=atof(vals[1]);
					sigmaMeterPer=atof(vals[2])*1.e-7;
					statusFlag=atoi(vals[0]);
	 				pvPut(sigmaMeterPri);
	 				pvPut(sigmaMeterHz);
	 				pvPut(sigmaMeterPer);
				}
%%			}
		
		} state monitor_inputs
	}

} /* End ss sigmaMeterDuo */

%{
void sigmaMeterWR(SS_ID ssId, struct UserVar *pVar, char *cmdStr, EV_ID sigmaMeterInMon)
{
 		int i, j, nloops, nchar;
 		double timeOut = 1.;
 		nloops = 20;
 		
 		efClear_sigmaMon(ssId, sigmaMeterInMon);
		pVar->sigmaMeterInTO =timeOut;
		seq_pvPut(ssId, pVar->sigmaMeterInTOIndex,  2);
		
		strcpy(pVar->sigmaMeterOut , cmdStr);
		strcpy(pVar->sigmaMeterRW, "Write/Read");

		seq_pvPut(ssId, pVar->sigmaMeterRWIndex,  2);
		seq_pvPut(ssId, pVar->sigmaMeterOutIndex,  2);
   		CDebug(5, "writeSigmaMeter: sigmaMeterOut=%s\n", pVar->sigmaMeterOut); 	
 
    	for (i=0; i<nloops; i++) {
         	epicsThreadSleep(.01);
       		if (seq_efTest(ssId, sigmaMeterInMon)) break;
    	}
    	
		seq_pvGet(ssId, pVar->sigmaMeterInIndex, 2);
		nchar = strlen(pVar->sigmaMeterIn);
		CDebug(5, "readSigmaMeter: nchar=%d timeOut=%f, nloops=%d, loops used=%d\n", nchar, timeOut, nloops, i); 	
		for (i=0; i<nchar; i++) {
			if (pVar->sigmaMeterIn[i] == 5) {
				for (j=i; j<nchar; j++) {
					pVar->sigmaMeterIn[j] = pVar->sigmaMeterIn[j+1];
				}
			}
		}	
		CDebug(5, "readSigmaMeter: %s\n", pVar->sigmaMeterIn); 	
		seq_efClear(ssId, sigmaMeterInMon);
}

void sigmaMeterR(SS_ID ssId, struct UserVar *pVar, EV_ID sigmaMeterInMon)
{
 		int i, j, nloops, nchar;
 		double timeOut;
 		nloops = 20;
 		timeOut=1.0;
 		
 		/* seq_efClear(ssId, sigmaMeterInMon); */
		efClear_sigmaMon(ssId, sigmaMeterInMon);
		
		pVar->sigmaMeterInTO =timeOut;
		seq_pvPut(ssId, pVar->sigmaMeterInTOIndex,  2);
		strcpy(pVar->sigmaMeterRW, "Read");
 		seq_pvGet(ssId, pVar->sigmaMeterProcIndex,  2);
		pVar->sigmaMeterProc=1-pVar->sigmaMeterProc;
		
		seq_pvPut(ssId, pVar->sigmaMeterRWIndex,  2);
 		seq_pvPut(ssId, pVar->sigmaMeterProcIndex,  2);

 		CDebug(5, "readSigmaMeter: pVar->sigmaMeterProc=%d\n", pVar->sigmaMeterProc); 	
    	for (i=0; i<nloops; i++) {
         	epicsThreadSleep(.01);
       		if (seq_efTest(ssId, sigmaMeterInMon)) break;
    	}
    	
		seq_pvGet(ssId, pVar->sigmaMeterInIndex, 2);
		nchar = strlen(pVar->sigmaMeterIn);
 		CDebug(5, "readSigmaMeter: nchar=%d timeOut=%f, nloops=%d, loops used=%d\n", nchar, timeOut, nloops, i); 	
		for (i=0; i<nchar; i++) {
			if (pVar->sigmaMeterIn[i] == 5) {
				for (j=i; j<nchar; j++) {
					pVar->sigmaMeterIn[j] = pVar->sigmaMeterIn[j+1];
				}
			}
		}	
		CDebug(5, "readSigmaMeter: %s\n", pVar->sigmaMeterIn); 	
		seq_efClear(ssId, sigmaMeterInMon);


}

static void efClear_sigmaMon(SS_ID ssId, EV_ID sigmaMeterInMon)
{
  seq_efClear(ssId, sigmaMeterInMon);
  return;
}


void sigmaMeterW(SS_ID ssId, struct UserVar *pVar, char *cmdStr)
{
 		double timeOut = 1.;
		pVar->sigmaMeterInTO =timeOut;
		seq_pvPut(ssId, pVar->sigmaMeterInTOIndex,  2);
 		strcpy(pVar->sigmaMeterOut , cmdStr);
		strcpy(pVar->sigmaMeterRW, "Write");
		seq_pvPut(ssId, pVar->sigmaMeterRWIndex,  2);
		seq_pvPut(ssId, pVar->sigmaMeterOutIndex,  2);
		CDebug(5, "writeSigmaMeter: sigmaMeterOut=%s\n", pVar->sigmaMeterOut); 		

}

void sigmaMeterWait(SS_ID ssId, struct UserVar *pVar, double timeOut, EV_ID sigmaMeterInMon)
{
 		int i, nloops, nchar;
 		nloops = 20;

 	
 		/* seq_efClear(ssId, sigmaMeterInMon); */
		efClear_sigmaMon(ssId, sigmaMeterInMon);
		pVar->sigmaMeterInTO =timeOut;
		seq_pvPut(ssId, pVar->sigmaMeterInTOIndex,  2);
		strcpy(pVar->sigmaMeterIEOS, "\005");
		seq_pvPut(ssId, pVar->sigmaMeterIEOSIndex,  2);
 		strcpy(pVar->sigmaMeterRW, "Read");
 		seq_pvGet(ssId, pVar->sigmaMeterProcIndex,  2);
		pVar->sigmaMeterProc=1-pVar->sigmaMeterProc;
		
		seq_pvPut(ssId, pVar->sigmaMeterRWIndex,  2);
 		seq_pvPut(ssId, pVar->sigmaMeterProcIndex,  2);

 		CDebug(5, "SigmaMeter: pVar->sigmaMeterProc=%d\n", pVar->sigmaMeterProc); 	
    	for (i=0; i<nloops; i++) {
       		if (seq_efTest(ssId, sigmaMeterInMon)) break;
    	}
		seq_pvGet(ssId, pVar->sigmaMeterInIndex, 2);
		nchar = strlen(pVar->sigmaMeterIn);
 		CDebug(5, "SigmaMeter: nchar=%d timeOut=%f, nloops=%d, loops used=%d\n", nchar, timeOut, nloops, i); 	
		strcpy(pVar->sigmaMeterIEOS, "\r\n");
		seq_pvPut(ssId, pVar->sigmaMeterIEOSIndex,  2);
 		CDebug(5, "SigmaMeter: %s\n", pVar->sigmaMeterIn); 	
		seq_efClear(ssId, sigmaMeterInMon);
}
}%
