program beamCheckTbl("P1=14IDA:, P2=14IDC:, P3=14IDB:")

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


int beamCheckTbl;
assign beamCheckTbl to "{P3}beamCheckTbl";
monitor beamCheckTbl;
evflag beamCheckTblMon; 
sync beamCheckTbl beamCheckTblMon;

/* IK added to monitor Cancel */

int beamCheckTblCancel;
assign beamCheckTblCancel to "{P3}beamCheckTblCancel";
monitor beamCheckTblCancel;
evflag beamCheckTblCancelMon; 
sync beamCheckTblCancel beamCheckTblCancelMon;

int iterations;
assign iterations to "{P3}beamCheckTblIter.VAL";


string status;
assign status to "{P3}beamCheckTblStatus.VAL";

/*
*   Detector Parameters
*/

int det_number; 
assign det_number to "{P3}beamCheckDetector.VAL";
monitor det_number;

/* Use WaveSurfer oscilliscope in pink mode */
int triggerMode;
assign triggerMode to "{P3}waveSurfer:triggerMode.VAL";

double det_val;
assign det_val to "{P3}waveSurfer:P1:last.VAL";

double det_count;
assign det_count to "{P3}waveSurfer:count.VAL";

/* Used Keithley in mono mode */
double det_val2;
assign det_val2 to "{P3}Keithley1:AcqTotalInv.VAL";

double det_count2;
assign det_count2 to "{P3}Keithley1:Start.PROC";


/*
*    Table Vertical Motion
*/

double posT;
assign posT to "{P3}table1.Y";


/* double MIP;		*/
/* assign MIP to "{P2}mir2Th.MIP";	*/


double deltaT;
assign deltaT to "{P3}beamCheckTblDelta.VAL";

double peakT;
assign peakT to "{P3}beamCheckTblPeak.VAL";

int peakTFound;
assign peakTFound to "{P3}beamCheckTblPkFd.VAL";


double position;

double posTSaved;
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


ss beamCheckTbl{
 
	state init {
		when() {
		peakTFound=0;
		} state monitorInputs 
	} 

    state monitorInputs {


       when(efTestAndClear(beamCheckTblMon) & (beamCheckTbl == 1)) {
	
	peakTFound=0;

        } state beamCheckT

	 when(efTestAndClear(beamCheckTblCancelMon) & (beamCheckTblCancel == 1)) {
	
        } state beamCheckC

	}

   state beamCheckC {
	when()	{
	if(beamCheckTbl == 0) beamCheckTblCancel=0;
	pvPut(beamCheckTblCancel);
	} state monitorInputs
	}

   state beamCheckT {
        when() {
			printf("\n");
 			printf("Vertical:\n");
%%			strcpy(pVar->status, "Vert Table Scanning.");
			pvPut(status);
            pvGet(deltaT);
            pvGet(posT);
	    posTSaved=posT;
            pvGet(iterations);
            origPos = posT;
            for (i=0; i<3; i++) {
		if (beamCheckTblCancel ==1) break;
		position = origPos+deltaT*(i-1);
                posT=position;
		det_count=1;det_count2=1;
                pvPut(posT, SYNC);
/*		MIP=1;				*/
/* %%              do {				*/
/*			pvGet(MIP);		*/
/* %%              } while(pVar->MIP > 0);	*/

		if (det_number == 0) pvPut(det_count,SYNC);
		if (det_number == 1) pvPut(det_count2,SYNC);
                if (det_number == 0) pvGet(det_val);
                if (det_number == 1) pvGet(det_val2);
		if (det_number == 1) det_val = det_val2;
             
%{              
                a[pVar->i][0]=pVar->posT*pVar->posT;
                a[pVar->i][1]=pVar->posT;                
                a[pVar->i][2]=1.;
                y[pVar->i]=pVar->det_val;
				printf("Position %f, Detector %e\n",pVar->posT, pVar->det_val);
}%
            } 
            icount=0;
            newPos = origPos;
            posT = newPos;
            pvPut(posT, SYNC);
%%          if (((y[1] <= y[0]) || (y[1] <= y[2]))&&  (pVar->beamCheckTblCancel ==0))  {
%{				do {
					if (pVar->beamCheckTblCancel ==1) break;
					if (y[0] > y[2]) 
						pVar->posT = pVar->newPos-pVar->deltaT;
					else
						pVar->posT = pVar->newPos+pVar->deltaT;
				
					printf("newPos = %f\n",pVar->posT);
}%					
					pvPut(posT, SYNC);
					newPos=posT;
					for (i=0; i<3; i++) {
						position = newPos+deltaT*(i-1);
						posT=position;
						det_count=1;det_count2=1;
						pvPut(posT);
						if (det_number == 0) pvPut(det_count,SYNC);
						if (det_number == 1) pvPut(det_count2,SYNC);
				                if (det_number == 0) pvGet(det_val);
				                if (det_number == 1) pvGet(det_val2);
						if (det_number == 1) det_val = det_val2;

%{              
						a[pVar->i][0]=pVar->posT*pVar->posT;
						a[pVar->i][1]=pVar->posT;                
						a[pVar->i][2]=1.;
						y[pVar->i]=pVar->det_val;
						printf("Position %f, Detector %e\n",pVar->posT, pVar->det_val);
}%
					}
					posT = newPos;
					pvPut(posT, SYNC);
					icount++;
					if (icount > iterations-1) break;
%%				}while(((y[1] <= y[0]) || (y[1] <= y[2])) && (pVar->beamCheckTblCancel ==0) ); /* IK */
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
				printf("Vert table maximum found at %f\n", pVar->peak);

}%
/*				posT=posTSaved;   return to the saved initial position */
				peakT=peak;

			/*	posT=peak;	*/
			/*	pvPut(posT);   */
				pvPut(peakT);
				
				
%%				strcpy(pVar->status, "Vert table maximum found.");
				pvPut(status);
				peakTFound=1;
				pvPut(peakTFound);

		
				
			}
			else {
				if (beamCheckTblCancel)
%%				strcpy(pVar->status, "Canceled. Moving to old pos");      /* IK */
				else
%%				strcpy(pVar->status, "No vert table maximum found.");
				pvPut(status);
			}
            
/*
*			Reset beamCheck Monitors
*/            

		/* IK */
		if (beamCheckTblCancel) {
		beamCheckTblCancel=0;
		pvPut(beamCheckTblCancel);
		posT=posTSaved;
		pvPut(posT);
		}
      		beamCheckTbl=0;
      		pvPut(beamCheckTbl);
/* return the table to the saved initial position   */
		posT=posTSaved;
		pvPut(posT);
				
		if (det_number == 0) {
			triggerMode = 1;
			pvPut(triggerMode);
		}
		} state monitorInputs
	}
}
