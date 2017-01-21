program beamCheckMono("P1=14IDA:, P2=14IDB:, M=m12, D=DAC1_3")

/*
*	Optimize monochromator in 14IDA by scanning monochromator DAC.If maxima is not found, then scan
*	monochromator theta motor
*       for this program original code of beamCheck.st by	T. Graber November 10, 2008
*	was modified
*
*
*/

%% #include <string.h>
%% #include "epicsTime.h"
%% #include <time.h>
%% #include <math.h>
%% #include <errlog.h>

/* This program must be compiled with the recursive option */
option +r;

#define Debug(L,FMT,V...) {  if(L <= debugLevel) \
                        { printf(FMT,##V); } }

#define CDebug(L,FMT,V...) {  if(L <= pVar->debugLevel) \
                        { printf(FMT,##V); } }


/* Define PVs */

/* Define variables for using combined Theta motor and DAC for optimizing mono */
int beamCheckMDT;
assign beamCheckMDT to "{P2}beamCheckMDT";
monitor beamCheckMDT;
evflag beamCheckMDTMon; 
sync beamCheckMDT beamCheckMDTMon;


/* Define variables for using DAC for optimizing mono */
int beamCheckMD;
assign beamCheckMD to "{P2}beamCheckMD";
monitor beamCheckMD;
evflag beamCheckMDMon; 
sync beamCheckMD beamCheckMDMon;

/* Define variables for using theta motor for optimizing mono */

int beamCheckMT;
assign beamCheckMT to "{P2}beamCheckMT";
monitor beamCheckMT;
evflag beamCheckMTMon; 
sync beamCheckMT beamCheckMTMon;

/* Define variables for CancelMono button */

int beamCheckMCancel;
assign beamCheckMCancel to "{P2}beamCheckMCancel";
monitor beamCheckMCancel;
evflag beamCheckMCancelMon; 
sync beamCheckMCancel beamCheckMCancelMon;

int iterations;
assign iterations to "{P2}beamCheckMIter.VAL";

int MonoAligned;
assign MonoAligned to "{P2}beamCheckMAligned.VAL";


string status;
assign status to "{P2}beamCheckMStatus.VAL";

/*
*   Detector Parameters
*/

/* use BPM QUAD detector for optimizations */
/* Maybe  need some Db for detector function: now it is using only vert sum and scanning constantly */
double det_val;
assign det_val to "{P2}EM1Sum2";  /* verify SUM1 OR SUM2   */

/* do not need to count for Quad Electrometer */
/* double det_count;	*/
/* assign det_count to "{P2}SimVal.PROC";	*/
/* This added to simulate intensity for the theta motor optimization with SimValMot record */
/* double det_val1;			*/
/* assign det_val1 to "{P2}SimValMot.VAL";		*/

/* double det_count1;				*/
/* assign det_count1 to "{P2}SimValMot.PROC";	*/

/*   Monochromator piezo optimization: */

double posMD;
assign posMD to "{P1}{D}.VAL";

double LHposMD;
assign LHposMD to "{P1}{D}.DRVH";

double LLposMD;
assign LLposMD to "{P1}{D}.DRVL";



double deltaMD;
assign deltaMD to "{P2}beamCheckDeltaMD.VAL";

/*
*    Monochromator theta motor optimization
*/

double posMT;
assign posMT to "{P1}{M}.VAL";

/* ADD DMOV VALUE FOR MONOCHTOMATOR theta motor */

int posMTDMOV;
assign posMTDMOV to "{P1}{M}.DMOV";

int posMTSTOP;
assign posMTSTOP to "{P1}{M}.STOP";

double deltaMT;
assign deltaMT to "{P2}beamCheckDeltaMT.VAL";


double position;
double origPos;
double newPos;
double peak;
double SaveLHMD;
double SaveLLMD;
double SavePosMD;
double SavePosMT;
double SaveDeltaMD;
double SaveDeltaMT;
int i;
int icount;
int NotFoundPiezo;  /* set to 1 if piezo optimization to be rerun, and for 2 if failed */
int NotFoundTheta;  /* set to 1 if motor theta optimization to be rerun and for 2 if failed */
int SetMDT;		/* set to 1 if piezo, and motor optimization is desired */

%{
    double a[3][3];
    double in[3][3];
    double y[3];
    double c[3];
    double det;
    int j;
}%

#define MAX(a,b) ((a)>(b)? (a): (b))
#define MIN(a,b) ((a)<(b)? (a): (b))



ss beamCheckMono{
 
	state init {
		when() {
		NotFoundPiezo=0;
		NotFoundTheta=0;
		SetMDT=0;
		printf("Initializing clause\n"); /* */

		} state monitorInputs 
	} 

    state monitorInputs {
	 when(efTestAndClear(beamCheckMDTMon) & (beamCheckMDT == 1)) {
	/*	beamCheckMDT=0;			comm out 9-22-09 */
	/*	pvPut(beamCheckMDT);		comm out 9-22-09 */
		SetMDT=1;
		MonoAligned=0;
		pvPut(MonoAligned);
        } state beamCheckMD
       when(efTestAndClear(beamCheckMDMon) & (beamCheckMD == 1)) {
		MonoAligned=0;
		pvPut(MonoAligned);
/*		printf("In Piezo clause\n");  */
        } state beamCheckMD

       when(efTestAndClear(beamCheckMTMon) & (beamCheckMT == 1)) {
		MonoAligned=0;
		pvPut(MonoAligned);
        } state beamCheckMT
	
	 when(efTestAndClear(beamCheckMCancelMon) & (beamCheckMCancel == 1)) {  
/*			printf("In Cancel clause\n");  */

        } state beamCheckMCancel    
        
        
	}
   
    state beamCheckMD {
        when() {
/* 		printf("\n");					*/
/*		printf("Monochromator Piezo:\n");		*/
%%		strcpy(pVar->status, "Monochromator Piezo Scanning.");
		pvPut(status);
		pvGet(deltaMD);
      		pvGet(posMD);
/* save old positions of piezo and limits for piezo */
		if (NotFoundPiezo <1)
		{

		SavePosMD=posMD;
		pvGet(LHposMD);
		pvGet(LLposMD);
		SaveLLMD=LLposMD;
		SaveLHMD=LHposMD;
		
		SaveDeltaMD=deltaMD;
		

/* define new position for limits which is 10% less the old range */
		
		LHposMD=SaveLHMD-0.1*(SaveLHMD-SaveLLMD);
		LLposMD=SaveLLMD+0.1*(SaveLHMD-SaveLLMD);

/* Reset Limits for those new values */
		pvPut(LHposMD);
		pvPut(LLposMD);
		
		}		

        	pvGet(iterations);
            	origPos = posMD;
		for (i=0; i<3; i++) {


		position = origPos+deltaMD*(i-1);
                posMD=position;
	/*	det_count=1;	*/
                pvPut(posMD,SYNC); /* make sure that DAC moved to the right position */
	 /*       pvPut(det_count,SYNC);	*/
			epicsThreadSleep(0.2);
                pvGet(det_val);

%{              
                a[pVar->i][0]=pVar->posMD*pVar->posMD;
                a[pVar->i][1]=pVar->posMD;                
                a[pVar->i][2]=1.;
                y[pVar->i]=pVar->det_val;
		printf("Position %f, Detector %e\n",pVar->posMD, pVar->det_val);
	
}%
		if (beamCheckMCancel)

			{
%%				strcpy(pVar->status, "Cancelled. Moving to old pos");
				pvPut(status);
			}
	
		if (beamCheckMCancel ==1)  break;  
            }
            icount=0;
            newPos = origPos;
%%          if (((y[1] <= y[0]) || (y[1] <= y[2])) &&(pVar->beamCheckMCancel==0)) {
%{				do {
/*					printf("first if statement\n");		*/
					if (y[0] > y[2]) 
						pVar->posMD = pVar->newPos-pVar->deltaMD;
					else
						pVar->posMD = pVar->newPos+pVar->deltaMD;
				
					printf("newPos = %f\n",pVar->posMD);
}%					
					pvPut(posMD, SYNC);
					newPos=posMD;
					for (i=0; i<3; i++) {

					

						position = newPos+deltaMD*(i-1);
						posMD=position;
					/*	det_count=1;	*/
						pvPut(posMD,SYNC);
					 /*       pvPut(det_count,SYNC);	*/
					epicsThreadSleep(0.2);
				                pvGet(det_val);
				               

%{              
						a[pVar->i][0]=pVar->posMD*pVar->posMD;
						a[pVar->i][1]=pVar->posMD;                
						a[pVar->i][2]=1.;
						y[pVar->i]=pVar->det_val;
						printf("Position %f, Detector %e\n",pVar->posMD, pVar->det_val);
					
}%

						if (beamCheckMCancel)

			{
%%				strcpy(pVar->status, "Cancelled. Moving to old pos");
				pvPut(status);
			}
	
				if (beamCheckMCancel ==1)  break;  
		
			}
				
					icount++;
					if (icount > iterations-1) break;
%%				}while(((y[1] <= y[0]) || (y[1] <= y[2])) && (pVar->beamCheckMCancel==0)) ;
%%			}


			if ((y[1] > y[0]) & (y[1] > y[2])) {
					printf("Calculation of the peak positions\n");
%{
				det=a[0][0]*(a[1][1]*a[2][2]-a[2][1]*a[1][2])-a[0][1]*(a[1][0]*a[2][2]-a[1][2]*a[2][0])+a[0][2]*(a[1][0]*a[2][1]-a[1][1]*a[2][0]);
    			in[0][0]=(a[1][1]*a[2][2]-a[2][1]*a[1][2])/det;
    			in[0][1]=-(a[1][0]*a[2][2]-a[1][2]*a[2][0])/det;
    			in[0][2]=(a[1][0]*a[2][1]-a[2][0]*a[1][1])/det;
    			in[1][0]=-(a[0][1]*a[2][2]-a[0][2]*a[2][1])/det;
    			in[1][1]=(a[0][0]*a[2][2]-a[0][2]*a[2][0])/det;
    			in[1][2]=-(a[0][0]*a[2][1]-a[2][0]*a[0][1])/det;
    			in[2][0]=(a[0][1]*a[1][2]-a[0][2]*a[1][1])/det;
    			in[2][1]=-(a[0][0]*a[1][2]-a[1][0]*a[0][2])/det;
    			in[2][2]=(a[0][0]*a[1][1]-a[1][0]*a[0][1])/det;
         
				for (j=0; j<3; j++) {
					c[j]=in[0][j]*y[0]+in[1][j]*y[1]+in[2][j]*y[2];
				}

				printf("a:%e b:%e c:%e\n", c[0],c[1],c[2]);
				pVar->peak=-c[1]/(2.*c[0]);
				printf("Minimum at %f\n", pVar->peak);

}%
				posMD=peak;
				pvPut(posMD, SYNC);
%%				strcpy(pVar->status, "Mono Piezo minimum found.");
				pvPut(status);
				MonoAligned=1;
				pvPut(MonoAligned);
				
				if (!beamCheckMCancel)
				{
				
				if (NotFoundPiezo>0) { NotFoundPiezo=0;deltaMD=deltaMD/2; pvPut(deltaMD);}
			}
			else {
%%				strcpy(pVar->status, "No Mono Piezo minimum found");
				pvPut(status);
				NotFoundPiezo=NotFoundPiezo+1;
			}
			if (beamCheckMCancel)
			{
%%				strcpy(pVar->status, "Cancelled. Moving to old pos");
				pvPut(status);
			}

				}


/*
*		Reset beamCheck Monitors
*/            if (( NotFoundPiezo<1)||( beamCheckMCancel))
		{
		beamCheckMD=0;
		pvPut(beamCheckMD);

	     if (beamCheckMDT)
		{	beamCheckMDT=0;			
			pvPut(beamCheckMDT);
		}

		SetMDT=0; 	/* do not perform theta optimization */

/* return to old limit positions and reset limits for old values */
		
		LHposMD=SaveLHMD;
		LLposMD=SaveLLMD;
		pvPut(LHposMD);
		pvPut(LLposMD);

		deltaMD=SaveDeltaMD;
		pvPut(deltaMD);
		
		if (beamCheckMCancel) 
		{
			posMD=SavePosMD;
			pvPut(posMD);
		}

		}
	      if ((NotFoundPiezo>0)& (NotFoundPiezo<2) & (!beamCheckMCancel)) /* double the DAC step, search once more */
		{
		deltaMD=deltaMD*2;
		pvPut(deltaMD);
		beamCheckMD=0;
		pvPut(beamCheckMD);
		beamCheckMD=1;
		pvPut(beamCheckMD);
		}
	      if ((NotFoundPiezo>1)& (!beamCheckMCancel))
		{
		
		beamCheckMD=0;
		pvPut(beamCheckMD);
		deltaMD=SaveDeltaMD;
		pvPut(deltaMD);
		NotFoundPiezo=0;

		
		
/* return to old limit positions and reset limits for old values */
/* return to old position in case of failure                */
		
		LHposMD=SaveLHMD;
		LLposMD=SaveLLMD;
		pvPut(LHposMD);
		pvPut(LLposMD);
/* do not like reversing to old position if optimization failed */
/*
		posMD=SavePosMD;
		pvPut(posMD);
*/	
		if (SetMDT>0)
		{
		SetMDT=0;
		posMD=(SaveLHMD+SaveLLMD)/2; /* Put DAC to the middle range */
		pvPut(posMD);

		beamCheckMT=1;
		pvPut(beamCheckMT);	
		
	
		
		}
		}

		if (beamCheckMCancel)
		{
		beamCheckMCancel=0;
		pvPut(beamCheckMCancel);
		}
		
		
		} state monitorInputs
	}

   state beamCheckMCancel {  					 
	when()  {              					 
		printf(" In beamCheckMcancel state\n");
		if ((beamCheckMD == 0) &( beamCheckMT ==0)) 
		{          
		beamCheckMCancel=0;
		pvPut(beamCheckMCancel);
		}				
	} state monitorInputs					
	}

   state beamCheckMT {
        when() {
			printf("\n");
 			printf("Monochromator Theta:\n");
%%			strcpy(pVar->status, "Monochromator Theta Scanning.");
			pvPut(status);
            pvGet(deltaMT);
            pvGet(posMT);

	   if (NotFoundTheta<1)
		{ SavePosMT=posMT;
		  SaveDeltaMT=deltaMT;	
		}

            pvGet(iterations);
            origPos = posMT;
            for (i=0; i<3; i++) {
		position = origPos+deltaMT*(i-1);
                posMT=position;
	/*	det_count1=1;	*/
                pvPut(posMT, SYNC);

%%		do {
			pvGet(posMTDMOV);
%%		} while (pVar->posMTDMOV<1);

	 /*       pvPut(det_count1,SYNC); */
                pvGet(det_val);          
	
             
%{              
                a[pVar->i][0]=pVar->posMT*pVar->posMT;
                a[pVar->i][1]=pVar->posMT;                
                a[pVar->i][2]=1.;
                y[pVar->i]=pVar->det_val;
				printf("Position %f, Detector %e\n",pVar->posMT, pVar->det_val);
}%


		if (beamCheckMCancel ==1){ posMTSTOP=1; pvPut(posMTSTOP,SYNC);

%%              do {
			pvGet(posMTDMOV);
%%              } while(pVar->posMTDMOV <1);

					} /* IK */
		if (beamCheckMCancel)
			{
%%				strcpy(pVar->status, "Cancelled. Moving to old pos");
				pvPut(status);
			}
	
		
		if (beamCheckMCancel ==1) break;

            } 
            icount=0;
		if (!beamCheckMCancel)
		{
            newPos = origPos;
            posMT = newPos;
            pvPut(posMT, SYNC);
		}



       
         /*       pvGet(det_val); 	  */

%%          if (((y[1] <= y[0]) || (y[1] <= y[2]))&& (pVar->beamCheckMCancel ==0)) {
%{				do {
					if (pVar->beamCheckMCancel ==1) break;
					if (y[0] > y[2]) 
						pVar->posMT = pVar->newPos-pVar->deltaMT;
					else
						pVar->posMT = pVar->newPos+pVar->deltaMT;
				
					printf("newPos = %f\n",pVar->posMT);
}%					
					pvPut(posMT, SYNC);
					newPos=posMT;
					for (i=0; i<3; i++) {
						position = newPos+deltaMT*(i-1);
						posMT=position;
				
						pvPut(posMT,SYNC); /* add SYNC */

%%						do {
							pvGet(posMTDMOV);
%%						} while (pVar->posMTDMOV<1);

					    /*    pvPut(det_count1,SYNC);  no counting for this detector */
				                pvGet(det_val);

%{              
						a[pVar->i][0]=pVar->posMT*pVar->posMT;
						a[pVar->i][1]=pVar->posMT;                
						a[pVar->i][2]=1.;
						y[pVar->i]=pVar->det_val;
						printf("Position %f, Detector %e\n",pVar->posMT, pVar->det_val);
}%

						if (beamCheckMCancel ==1){ posMTSTOP=1; pvPut(posMTSTOP,SYNC);

%%             					 do {
							pvGet(posMTDMOV);
%%            					  } while(pVar->posMTDMOV <1);

					       	} /* IK */
						if (beamCheckMCancel)
						{
%%							strcpy(pVar->status, "Cancelled. Moving to old pos");
							pvPut(status);
						}
	
		
						if (beamCheckMCancel ==1) break;


					}
					if (beamCheckMCancel ==1) break;
					if (!beamCheckMCancel){
					posMT = newPos;
					pvPut(posMT, SYNC);}
					icount++;
					if (icount > iterations-1) break;
%%				}while(((y[1] <= y[0]) || (y[1] <= y[2]))&& (pVar->beamCheckMCancel==0)) ;
%%			}


			if ((y[1] > y[0]) & (y[1] > y[2])) {
%{
			det=a[0][0]*(a[1][1]*a[2][2]-a[2][1]*a[1][2])-a[0][1]*(a[1][0]*a[2][2]-a[1][2]*a[2][0])+a[0][2]*(a[1][0]*a[2][1]-a[1][1]*a[2][0]);
    			in[0][0]=(a[1][1]*a[2][2]-a[2][1]*a[1][2])/det;
    			in[0][1]=-(a[1][0]*a[2][2]-a[1][2]*a[2][0])/det;
    			in[0][2]=(a[1][0]*a[2][1]-a[2][0]*a[1][1])/det;
    			in[1][0]=-(a[0][1]*a[2][2]-a[0][2]*a[2][1])/det;
    			in[1][1]=(a[0][0]*a[2][2]-a[0][2]*a[2][0])/det;
    			in[1][2]=-(a[0][0]*a[2][1]-a[2][0]*a[0][1])/det;
    			in[2][0]=(a[0][1]*a[1][2]-a[0][2]*a[1][1])/det;
    			in[2][1]=-(a[0][0]*a[1][2]-a[1][0]*a[0][2])/det;
    			in[2][2]=(a[0][0]*a[1][1]-a[1][0]*a[0][1])/det;
         
				for (j=0; j<3; j++) {
					c[j]=in[0][j]*y[0]+in[1][j]*y[1]+in[2][j]*y[2];
				}

				printf("a:%e b:%e c:%e\n", c[0],c[1],c[2]);
				pVar->peak=-c[1]/(2.*c[0]);
				printf("Mono Theta minimum found at %f\n", pVar->peak);

}%
				posMT=peak;

/* add to ensure during the cancel the motor is stopped before moving        */
			for( i=0; i++; i<1000)
			{
			pvGet(posMTDMOV);
	 		if (posMTDMOV==1){pvPut(posMT); break; }
			}
/* end  add here        */

			/*	pvPut(posMT); */
				
%%				strcpy(pVar->status, "Mono Theta  minimum found.");
				pvPut(status);

				MonoAligned=1;
				pvPut(MonoAligned);
				if(NotFoundTheta>0) {NotFoundTheta=0;deltaMT=deltaMT/2; pvPut(deltaMT);}
				
			}
			else {
%%				strcpy(pVar->status, "No Mono Theta minimum found.");
				pvPut(status);
			if (beamCheckMCancel)
			{
%%				strcpy(pVar->status, "Cancelled. Moving to old pos");
				pvPut(status);
			}
	
				NotFoundTheta=NotFoundTheta+1;
			}
            
/*
*			Reset beamCheck Monitors
*/            
      	        if ((NotFoundTheta<1)|| (beamCheckMCancel))
		{
		beamCheckMT=0;
      		pvPut(beamCheckMT);
		deltaMT=SaveDeltaMT;
		pvPut(deltaMT);


		  if (beamCheckMDT)
		{	beamCheckMDT=0;			
			pvPut(beamCheckMDT);
		}


		if (beamCheckMCancel)
		{
		posMT=SavePosMT;

/* add to ensure during the cancel the motor is stopped before moving        */
			for( i=0; i++; i<1000)
			{
			pvGet(posMTDMOV);
	 		if (posMTDMOV==1){pvPut(posMT); break; }
			}
/*      */
		}

		}
		if((NotFoundTheta>0)&(NotFoundTheta<2 )& (!beamCheckMCancel))
		{
		deltaMT=deltaMT*2;
		pvPut(deltaMT);
		beamCheckMT=0;
		pvPut(beamCheckMT);
		beamCheckMT=1;
		pvPut(beamCheckMT);
		}
		if ((NotFoundTheta>1) & (!beamCheckMCancel))
		{
		deltaMT=SaveDeltaMT;
		pvPut(deltaMT);
		beamCheckMT=0;
		pvPut(beamCheckMT);


		  if (beamCheckMDT)
		{	beamCheckMDT=0;			
			pvPut(beamCheckMDT);
		}


		NotFoundTheta=0;



/* if peak position is not found return to old position value - do not like it */

/*		posMT=SavePosMT;
		pvPut(posMT);
*/
		}
		} state monitorInputs
	}
}
