program beamCheck("P1=14IDA:, P2=14IDC:, P3=14IDB:")

/*
*	Optimize beam in 14IDB by scanning the vertical and horizontal mirrors.
*	T. Graber November 10, 2008
*
*	Added option to switch to a different detector for mono mode.
*	R. Henning December 15, 2008
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
int beamCheckComb;
assign beamCheckComb to "{P3}beamCheckComb";
monitor beamCheckComb;
evflag beamCheckCombMon; 
sync beamCheckComb beamCheckCombMon;

int beamCheckV;
assign beamCheckV to "{P3}beamCheckV";
monitor beamCheckV;
evflag beamCheckVMon; 
sync beamCheckV beamCheckVMon;

int beamCheckH;
assign beamCheckH to "{P3}beamCheckH";
monitor beamCheckH;
evflag beamCheckHMon; 
sync beamCheckH beamCheckHMon;

/* IK added to monitor Cancel */

int beamCheckCancel;
assign beamCheckCancel to "{P3}beamCheckCancel";
monitor beamCheckCancel;
evflag beamCheckCancelMon; 
sync beamCheckCancel beamCheckCancelMon;

int iterations;
assign iterations to "{P3}beamCheckIter.VAL";

/* IK added for checking alignment status */

int beamCheckVAln;
assign beamCheckVAln to "{P3}beamCheckVAln.VAL";

int beamCheckHAln;
assign beamCheckHAln to "{P3}beamCheckHAln.VAL";

string status;
assign status to "{P3}beamCheckStatus.VAL";

/*
*   Detector Parameters
*/

int det_number; 
assign det_number to "{P3}beamCheckDetector.VAL";
monitor det_number;

/* Use WaveSurfer oscilliscope in pink mode */
int triggerMode;
assign triggerMode to "{P3}waveSurfer:triggerMode.VAL";

int triggerNum;
assign triggerNum to "{P3}waveSurfer:triggers";

double det_val;
assign det_val to "{P3}waveSurfer:P1:last.VAL";

double det_count;
assign det_count to "{P3}waveSurfer:count.VAL";

/* Used Keithley in mono mode */
double det_val2;
assign det_val2 to "{P3}Keithley1:AcqTotalInv.VAL";

double det_count2;
assign det_count2 to "{P3}Keithley1:Start.PROC";

double det_val3;
assign det_val3 to "{P3}waveSurfer:P2:last.VAL";

double det_val4;
assign det_val4 to "{P3}waveSurfer:P1:mean.VAL";

double det_val5;
assign det_val5 to "{P3}waveSurfer:P1:sdev.VAL";



/*
*   Vertical Motion
*/

double posV;
assign posV to "{P1}DAC1_4.VAL";

double deltaV;
assign deltaV to "{P3}beamCheckDeltaV.VAL";

/*
*    Horizontal Motion
*/

double posH;
assign posH to "{P2}mir2Th.VAL";


double MIP;
assign MIP to "{P2}mir2Th.MIP";

int posHSTOP;
assign posHSTOP to "{P2}mir2Th.STOP";

int posHDMOV;
assign posHDMOV to "{P2}mir2Th.DMOV";

double deltaH;
assign deltaH to "{P3}beamCheckDeltaH.VAL";

/* JJ vertical slits aperture opening for standard deviation values optimization */
/* currently we move it to 10 um for optimization of SVED.MEAN   */

double posJJY;
assign posJJY to "{P3}m27.VAL";

double posJJX;
assign posJJX to "{P3}m25.VAL";



double position;
double posVSaved;
double posHSaved;
double posJJYSaved;
double posJJXSaved;
int triggerNumSaved;
double origPos;
double newPos;
double peak;
int i;
int icount;

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
#define posJJYScan 0.01
#define posJJYst 0.07
#define posJJXst 0.14
#define triggerNumDefault 10


ss beamCheck{
 
	state init {
		when() {
		} state monitorInputs 
	} 

    state monitorInputs {
       when(efTestAndClear(beamCheckVMon) & (beamCheckV == 1)) {
/* IK */
	beamCheckVAln=0;
	pvPut(beamCheckVAln);

        } state beamCheckV

       when(efTestAndClear(beamCheckHMon) & (beamCheckH == 1)) {
/* IK */
	beamCheckHAln=0;
	pvPut(beamCheckHAln);

        } state beamCheckH
/* commented out for future testing 6-1-09 */
	 when(efTestAndClear(beamCheckCancelMon) & (beamCheckCancel == 1)) {  

        } state beamCheckCancel           
        
       when(efTestAndClear(beamCheckCombMon) & (beamCheckComb == 1)) {
			beamCheckV=1;
			pvPut(beamCheckV);
			beamCheckH=1;
			pvPut(beamCheckH);
			efSet(beamCheckVMon);
			efSet(beamCheckHMon);
/*			beamCheckComb = 0;
			pvPut(beamCheckComb); */
/* IK */
			beamCheckVAln=0;
			pvPut(beamCheckVAln);
/* IK */
			beamCheckHAln=0;
			pvPut(beamCheckHAln);

        } state monitorInputs
        
	}

/* IK add state code for Cancel	for later testing 6-1-09	 */
    state beamCheckCancel {  					 
	when()  {              					 
		
		if ((beamCheckV == 0) &( beamCheckH ==0))           
		beamCheckCancel=0;
		pvPut(beamCheckCancel);				
	} state monitorInputs					
	}							
   
    state beamCheckV {
        when() {
 		printf("\n");
		printf("Vertical:\n");
%%		strcpy(pVar->status, "Vertical Scanning.");
		pvPut(status);
		pvGet(deltaV);
      		pvGet(posV);
		posVSaved=posV; /* IK save initial V position */
		/* save JJY, and JJX pos, use st value for alignment */
		 if(det_number<3){
  			pvGet(posJJY); posJJYSaved=posJJY; posJJY=posJJYst; pvPut(posJJY);
				}
		pvGet(posJJX); posJJXSaved=posJJX; posJJX=posJJXst; pvPut(posJJX);

	        if(det_number==3){
			pvGet(posJJY); posJJYSaved=posJJY; posJJY=posJJYScan; pvPut(posJJY);
			pvGet(triggerNum); triggerNumSaved=triggerNum; triggerNum=triggerNumDefault; pvPut(triggerNum);
					}

        	pvGet(iterations);
            	origPos = posV;
		for (i=0; i<3; i++) {
                if (beamCheckCancel ==1) break; /* IK */
		position = origPos+deltaV*(i-1);
                posV=position;
		det_count=1;det_count2=1;
                pvPut(posV);


 		if ((det_number == 0) || (det_number == 2) || (det_number == 3)) pvPut(det_count,SYNC);
		if (det_number == 1) pvPut(det_count2,SYNC);
	        if (det_number == 0) pvGet(det_val);
		if (det_number == 2) {pvGet(det_val3); det_val = det_val3;}
		if (det_number == 3) {pvGet(det_val4); pvGet(det_val5); det_val=-det_val5/det_val4;}
   		if (det_number == 1) pvGet(det_val2);
		if (det_number == 1) det_val = det_val2;


/*		if (det_number == 0) pvPut(det_count,SYNC);		*/
/*		if (det_number == 1) pvPut(det_count2,SYNC);		*/
/*                if (det_number == 0) pvGet(det_val);			*/
/*                if (det_number == 1) pvGet(det_val2);   		*/
/*		if (det_number == 1) det_val = det_val2;		*/

%{              
                a[pVar->i][0]=pVar->posV*pVar->posV;
                a[pVar->i][1]=pVar->posV;                
                a[pVar->i][2]=1.;
                y[pVar->i]=pVar->det_val;
		printf("Position %f, Detector %e\n",pVar->posV, pVar->det_val);
}%
/*            } 		moved after cancel statement */

/* add beamcheckCancel statement 9-24-09 */


		if (beamCheckCancel)

			{
%%				strcpy(pVar->status, "Cancelled. Moving to old pos");
				pvPut(status);
			}
	
		if (beamCheckCancel ==1)  break;  
            }

/* end of beamcheckcancel statement 9-24-09 */

            icount=0;
            newPos = origPos;
%%          if (((y[1] <= y[0]) || (y[1] <= y[2])) &&(pVar->beamCheckCancel==0)) {
%{				do {
					if (y[0] > y[2]) 
						pVar->posV = pVar->newPos-pVar->deltaV;
					else
						pVar->posV = pVar->newPos+pVar->deltaV;
				
					printf("newPos = %f\n",pVar->posV);
}%					
					pvPut(posV, SYNC);
					newPos=posV;
					for (i=0; i<3; i++) {
						if (beamCheckCancel ==1) break; /* IK */
						position = newPos+deltaV*(i-1);
						posV=position;
						det_count=1;det_count2=1;
						pvPut(posV);
						
						if ((det_number == 0) || (det_number == 2) || (det_number == 3)) pvPut(det_count,SYNC);
						if (det_number == 1) pvPut(det_count2,SYNC);
				                if (det_number == 0) pvGet(det_val);
						if (det_number == 2) {pvGet(det_val3); det_val =det_val3;}
						if (det_number == 3) {pvGet(det_val4); pvGet(det_val5); det_val=-det_val5/det_val4;}
				                if (det_number == 1) pvGet(det_val2);
						if (det_number == 1) det_val = det_val2;

%{              
						a[pVar->i][0]=pVar->posV*pVar->posV;
						a[pVar->i][1]=pVar->posV;                
						a[pVar->i][2]=1.;
						y[pVar->i]=pVar->det_val;
						printf("Position %f, Detector %e\n",pVar->posV, pVar->det_val);
}%
					}
					icount++;
					if (icount > iterations-1) break;
%%				}while(((y[1] <= y[0]) || (y[1] <= y[2])) && (pVar->beamCheckCancel==0)); /* IK */
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
				printf("Maximum at %f\n", pVar->peak);

}%
				posV=peak;
				pvPut(posV);
%%				strcpy(pVar->status, "Vertical maximum found.");
				pvPut(status);
				/* IK */
				beamCheckVAln=1;
				pvPut(beamCheckVAln);
			}
			else {
				if (beamCheckCancel)
%%				strcpy(pVar->status, "Canceled. Moving to old pos");      /* IK */
				else
%%				strcpy(pVar->status, "No vertical maximum found.");
				pvPut(status);
			}


/*
*		Reset beamCheck Monitors
*/            
		/* IK */
		if (beamCheckCancel) {
		if (beamCheckH==1){ beamCheckH=0; pvPut(beamCheckH);}
		if (beamCheckComb==1) { beamCheckComb=0; pvPut(beamCheckComb);}
		beamCheckCancel=0;
		pvPut(beamCheckCancel);
		posV=posVSaved;
		pvPut(posV);
	
		if( det_number ==3 ){
		posJJY=posJJYSaved;
		pvPut(posJJY);
		triggerNum=triggerNumSaved;
		pvPut(triggerNum);
		}
		}
		beamCheckV=0;
		pvPut(beamCheckV);

		posJJY=posJJYSaved;
		pvPut(posJJY);
		posJJY=posJJXSaved;
		pvPut(posJJX);

		if (det_number == 0 || det_number ==2 || det_number ==3 ) {
			triggerMode = 1;
			pvPut(triggerMode);
		}

		if ( det_number ==3 ) {
			posJJY=posJJYSaved;
			pvPut(posJJY);
			triggerNum=triggerNumSaved;
			pvPut(triggerNum);
		}
		} state monitorInputs
	}


/* for beamCheckH it was added additional code so afer Cancel button breaks the loop it will be ensured that the motor is not moving */
/* when next command to move is issued to prevent the motor from hanging  - IK */

   state beamCheckH {
        when() {
			printf("\n");
 			printf("Horizontal:\n");
%%			strcpy(pVar->status, "Horizontal Scanning.");
			pvPut(status);
            pvGet(deltaH);
            pvGet(posH);
	    posHSaved=posH; /* IK save initial position */
            pvGet(iterations);
            origPos = posH;


		pvGet(posJJY); posJJYSaved=posJJY; posJJY=posJJYst; pvPut(posJJY); /* save JJY, and JJX pos, use st value for alignment */
		pvGet(posJJX); posJJXSaved=posJJX; posJJX=posJJXst; pvPut(posJJX);



		if (det_number == 3) {
			det_number=0;
			pvPut(det_number);
			}		

            for (i=0; i<3; i++) {

		position = origPos+deltaH*(i-1);
                posH=position;
		det_count=1;det_count2=1;
		
                pvPut(posH, SYNC);
		
	/*	MIP=1; */
%%              do {
			pvGet(posHDMOV);
%%              } while(pVar->posHDMOV <1);

/* added detector 2 and 3  IK */
	
		if ((det_number == 0) || (det_number == 2) || (det_number == 3)) pvPut(det_count,SYNC);
		if (det_number == 1) pvPut(det_count2,SYNC);
		if (det_number == 0) pvGet(det_val);
		if (det_number == 2) {pvGet(det_val3); det_val =det_val3;}
/*		if (det_number == 3) {pvGet(det_val4); pvGet(det_val5); det_val=det_val5/det_val4;}		*/
		if (det_number == 1) pvGet(det_val2);
		if (det_number == 1) det_val = det_val2;
		

/*		if (det_number == 0) pvPut(det_count,SYNC);		*/
/*		if (det_number == 1) pvPut(det_count2,SYNC);		*/
/*                if (det_number == 0) pvGet(det_val);			*/
/*                if (det_number == 1) pvGet(det_val2);			*/
/*		if (det_number == 1) det_val = det_val2;		*/
             
%{              
                a[pVar->i][0]=pVar->posH*pVar->posH;
                a[pVar->i][1]=pVar->posH;                
                a[pVar->i][2]=1.;
                y[pVar->i]=pVar->det_val;
				printf("Position %f, Detector %e\n",pVar->posH, pVar->det_val);

}%

		if (beamCheckCancel ==1){ posHSTOP=1; pvPut(posHSTOP,SYNC);

%%              do {
			pvGet(posHDMOV);
%%              } while(pVar->posHDMOV <1);

					} /* IK */
		
		if (beamCheckCancel ==1) break;
			
            } 
            icount=0;
		if (!beamCheckCancel)
		{
            newPos = origPos;
            posH = newPos;
		
            pvPut(posH, SYNC);
		
		}
%%          if (((y[1] <= y[0]) || (y[1] <= y[2]))&& (pVar->beamCheckCancel ==0)) {
%{				do {
					if (pVar->beamCheckCancel ==1) break;
				
					if (y[0] > y[2]) 
						pVar->posH = pVar->newPos-pVar->deltaH;
					else
						pVar->posH = pVar->newPos+pVar->deltaH;
				
					printf("newPos = %f\n",pVar->posH);
}%					
					
					pvPut(posH, SYNC);
						
					newPos=posH;
					for (i=0; i<3; i++) {
					
						position = newPos+deltaH*(i-1);
						posH=position;
						det_count=1;det_count2=1;

						
						pvPut(posH, SYNC);     /*why not SYNC? IK add SYNC but may be need to reverse */


						/* added detector 2 and 3  IK */
	
						if ((det_number == 0) || (det_number == 2) || (det_number == 3)) pvPut(det_count,SYNC);
						if (det_number == 1) pvPut(det_count2,SYNC);
						if (det_number == 0) pvGet(det_val);
						if (det_number == 2) {pvGet(det_val3); det_val =det_val3;}
					/*	if (det_number == 3) {pvGet(det_val4); pvGet(det_val5); det_val=det_val5/det_val4;}		*/
						if (det_number == 1) pvGet(det_val2);
						if (det_number == 1) det_val = det_val2;
		

							
/*		if (det_number == 0) pvPut(det_count,SYNC);		*/
/*		if (det_number == 1) pvPut(det_count2,SYNC);		*/
/*		 if (det_number == 0) pvGet(det_val);			*/
/*		 if (det_number == 1) pvGet(det_val2);			*/
/*		if (det_number == 1) det_val = det_val2;		*/


%{              
						a[pVar->i][0]=pVar->posH*pVar->posH;
						a[pVar->i][1]=pVar->posH;                
						a[pVar->i][2]=1.;
						y[pVar->i]=pVar->det_val;
						printf("Position %f, Detector %e\n",pVar->posH, pVar->det_val);
}%
						if (beamCheckCancel ==1){ posHSTOP=1; pvPut(posHSTOP,SYNC);
%%              							do {
										pvGet(posHDMOV);
%%            								   } while(pVar->posHDMOV <1);


									} /* ensure that the STOP command does stop the motor IK */
						
						if (beamCheckCancel ==1) break;
					
				
							}

					if (beamCheckCancel ==1) break;
					if (!beamCheckCancel)
					{
					
						posH = newPos;
					
						pvPut(posH, SYNC);
					}
					icount++;
					if (icount > iterations-1) break;
%%				}while(((y[1] <= y[0]) || (y[1] <= y[2]))&& (pVar->beamCheckCancel==0)); /* IK */
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
				printf("Horizontal maximum found at %f\n", pVar->peak);

}%
				posH=peak;

%%              							do {
										pvGet(posHDMOV);
%%            								   } while(pVar->posHDMOV<1);

/* add to ensure during the cancel the motor is stopped before moving        */
			for( i=0; i++; i<1000)
			{
			pvGet(posHDMOV);
/*                      printf(" LOOP i HDMOV = %i\n",posHDMOV);                 IK -troubleshooting */
	 		if (posHDMOV==1){	pvPut(posH); break; }
			}
/* end  add here        */
				
/*				pvPut(posH);				comment out old command which is now in the loop - IK	*/
				
%%				strcpy(pVar->status, "Horizontal maximum found.");
				pvPut(status);

			/* IK */
				beamCheckHAln=1;
				pvPut(beamCheckHAln);
				
			}
			else {
				if (beamCheckCancel)
%%				strcpy(pVar->status, "Canceled. Moving to old pos");      /* IK */
				else
%%				strcpy(pVar->status, "No horizontal maximum found.");
				pvPut(status);
			}
            
/*
*			Reset beamCheck Monitors
*/            

		/* IK */
		if (beamCheckCancel) {
		beamCheckCancel=0;
		pvPut(beamCheckCancel);
		posH=posHSaved;
		
	
%%              							do {
										pvGet(posHDMOV);
%%            								   } while(pVar->posHDMOV <1);
		
		for( i=0; i++; i<1000)
		{
			pvGet(posHDMOV);
/*                      printf(" LOOP i HDMOV = %i\n",posHDMOV);                 IK -troubleshooting */
	 		if (posHDMOV==1){	pvPut(posH); break; }
		}
			
		
		}

      		beamCheckH=0;
      		pvPut(beamCheckH);

		posJJY=posJJYSaved;
		pvPut(posJJY);
		posJJY=posJJXSaved;
		pvPut(posJJX);


		if ((beamCheckV == 0) & (beamCheckComb == 1)) {
			beamCheckComb = 0;
			pvPut(beamCheckComb);
		}			
		if (det_number == 0 || det_number == 2 || det_number ==3) {
			triggerMode = 1;
			pvPut(triggerMode);
		}
		} state monitorInputs
	}
}
