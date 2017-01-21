program IDB_MAD("P1=14IDA:, P2=14IDB:, P3=IDC:,  M1=m12, M2=m3, M3=m8, M4=m27, M5=m25")

/*
*	This program will read tabulated Element energy from the specified template.
*	It will move monochromator to the specified energy, align system using beamCheck.st and beamCheckMono.st
*	It will load Enegfy scan parameters and perform energy scan.
*	Optimize monochromator in 14IDA by scanning monochromator DAC.If maxima is not found, then scan
*	monochromator theta motor. Optimize mirrors: vertical using DAc, Horizontal using theta motor
*       Element selection, defining the ROI, set up detector for the energy scans and setting up the scans is done through the database
*	
*       here M1 is a monotheta motor, M2 is Detector z motor, m3 is the beamstop translation, M4 is JJY aperture, M5=JJX aperture
*
*/

%% #include <string.h>
%% #include "epicsTime.h"
%% #include <time.h>
%% #include <math.h>
%% #include <errlog.h>


#define EnGapChange 15.000
#define GapOffset 0.150
#define MaxU23 20.144
#define MaxU27 17.000
#define MonoMovingTimeout 100
#define DetectorTimeout  100
#define MinSRCurrent 50.00
#define YES 1
#define NO 0
#define AlignmentTimeout 300
#define KEITHLEY 1
#define VSLIT 0.07
#define HSLIT 0.14
#define AUTO 1
#define DEADTIME 0.1



/* This program must be compiled with the recursive option */
option +r;

#define Debug(L,FMT,V...) {  if(L <= debugLevel) \
                        { printf(FMT,##V); } }

#define CDebug(L,FMT,V...) {  if(L <= pVar->debugLevel) \
                        { printf(FMT,##V); } }


/* Define PVs */

/* Define variables for the beamline alignment, providing beamline alignment status information */
/* and turning the feedback on and off for the monochromator and mirrors  */

/* Define variables for using combined Theta motor and DAC for optimizing mono */
int AlignMono;
assign AlignMono to "{P2}beamCheckMD";
monitor AlignMono;
evflag AlignMonoMon; 
sync AlignMono AlignMonoMon;
 

/* Define variable to check Monochromator alignment status */
int MonoAligned;
assign MonoAligned to "{P2}beamCheckMAligned"; /* add to the beam Check Mono */


/* Define variables for using combined Theta motor and DAC for optimizing mirrors */
int AlignMirror;
assign AlignMirror to "{P2}beamCheckComb";
monitor AlignMirror;
evflag AlignMirrorMon; 
sync AlignMirror AlignMirrorMon;
 

/* Define variable to check Vertical mirror alignment status */
int VMirrorAligned;
assign VMirrorAligned to "{P2}beamCheckVAln";   /* add to the beamCheck */


/* Define variable to check Horizontal mirror alignment status */
int HMirrorAligned;
assign HMirrorAligned to "{P2}beamCheckHAln";   /* add to the beamCheck */


/* Define variable to get the Flux value for the Monochromator alignment */
double MonoFlux;
assign MonoFlux to "{P2}EM1Sum2.VAL";

/* Define variable to get the Flux Value for mirror alignment */
double MirrorFlux;
assign MirrorFlux to "{P2}Keithley1:AcqTotalInv.VAL";


/* Define variable to assign a detector for  mirrors alignment */
int DetectorMirrors;
assign DetectorMirrors to "{P2}beamCheckDetector.VAL";


/* Define variables for initiating Alignment procedure */
int AlignAll;
assign AlignAll to "{P2}AlignAll.VAL";
monitor AlignAll;
evflag AlignAllMon; 
sync AlignAll AlignAllMon;

/* Define variables for initiating Alignment procedure */
int CancelAll;
assign CancelAll to "{P2}CancelAlignment.VAL";
monitor CancelAll;
evflag CancelAllMon; 
sync CancelAll CancelAllMon;

int CancelMirrors;
assign CancelMirrors to "{P2}beamCheckCancel.VAL";

int CancelMono;
assign CancelMono to "{P2}beamCheckMCancel.VAL";



/* Define variables for driving JJ slits at their standard location  */
double JJVSize;
assign JJVSize to "{P2}{M4}.VAL";
int JJVSizeDMOV;
assign JJVSizeDMOV to "{P2}{M4}.DMOV";
int JJVSizeRBV;
assign JJVSizeRBV to "{P2}{M4}.RBV";

/* Define variables for driving JJ slits at their standard location  */
double JJHSize;
assign JJHSize to "{P2}{M5}.VAL";
int JJHSizeDMOV;
assign JJHSizeDMOV to "{P2}{M5}.DMOV";
int JJHSizeRBV;
assign JJHSizeRBV to "{P2}{M5}.RBV";


/* Define variable to turn on and off monochromator feedback */
int MonoFeedback;
assign MonoFeedback "{P1}mono_pid1.FBON";

/* Define synchrotron Ring current for Mono PID calculations */
double RingCurrent;
assign RingCurrent "S:SRcurrentAI.VAL";


/* Define Monochromator PID Max Current in calc  for feedback calculations */
double MonoPIDIntMax;
assign MonoPIDIntMax to "{P1}mono_pid1_incalc.F";

/* Define Monochromator PID Ring Current in calc  for feedback calculations */
double MonoPIDCurrent;
assign MonoPIDCurrent to "{P1}mono_pid1_incalc.E";

/* Define variable to turn on and off Vertical mirror feedback */
int VMirrorFeedback;
assign VMirrorFeedback "{P1}vmirror_pid1.FBON";

/* Define variables to set mirror offsets for PID */
double VMirrorPIDF;
assign VMirrorPIDF to "{P1}vmirror_pid1_incalc.F";

double VMirrorPIDG;
assign VMirrorPIDG to "{P1}vmirror_pid1_incalc.G";


/* verify are there any calculations needed for the mirror feedback ? */

/* Assign variable to define status of the alignment   verify VAL field -OK */
string AlignmentStatus;
assign AlignmentStatus "{P2}AlignmentStatus.VAL";

/* Assign variable to define status of components during energy scan */
string ScanStatus;
assign ScanStatus "{P2}ScanStatus.VAL";

/* Assign variable to define status of monochromator  */
string MonoStatus;
assign MonoStatus "{P2}MonoStatus.VAL";


/* Define variable for moving energy and indulators to a desired location */

/* Define variable to read Desired Energy */
double DesiredEnergy;
assign DesiredEnergy to "{P2}DesiredEnergy.VAL";



/* Define variable to check DriveEnergy -Move button */
int DriveEnergy;
assign DriveEnergy to "{P2}DriveEnergy";
monitor DriveEnergy;
evflag DriveEnergyMon; 
sync DriveEnergy DriveEnergyMon;

/* Define variable to Drive Monochromator Energy */
double MonoEnergy;
assign MonoEnergy to "{P1}BraggEAO.VAL";

/* Define variable to read back  Monochromator Energy -OK */
double MonoEnergyRBV;
assign MonoEnergyRBV to "{P1}BraggERdbkAO";

/* Define variable to verify that Monochromator is done moving*/
double MonoEnergyDMOV;
assign MonoEnergyDMOV to "{P1}KohzuMoving";

/* Define variable to check the state of Monochromator: Manual or Auto */
double MonoMode;
assign MonoMode to "{P1}KohzuModeBO.VAL";




/* Define variable to Drive U27 */
double U27;
assign U27 to "{P1}U27Eng.VAL";

/* Define variable to DMOV  U27 */
int U27DMOV;
assign U27DMOV to "{P1}U27Eng.DMOV";

/* Define readback variable */
double U27RBV;
/* assign U27RBV to "{P1}U27Eng.SET";   */
assign U27RBV to "ID14us:Energy.VAL";





/* Define variable to Drive U23 */
double U23;
assign U23 to "{P1}U23Eng.VAL";



/* Define variable to readback U23 */
int U23DMOV;
assign U23DMOV to "{P1}U23Eng.DMOV";

/* Define readback variable */
double U23RBV;
/*  assign U23RBV to "{P1}U23Eng.SET";           */
assign U23RBV to "ID14ds:Energy.VAL";





/* Define PV's to Scan the energy */

int StartEnergyScan;
assign StartEnergyScan to "{P2}StartScan.VAL";
monitor StartEnergyScan;
evflag StartEnergyScanMon; 
sync StartEnergyScan StartEnergyScanMon;

int AbortEnergyScan;
assign AbortEnergyScan to "{P2}AbortScan";
monitor AbortEnergyScan;
evflag AbortEnergyScanMon; 
sync AbortEnergyScan AbortEnergyScanMon;

/* define fluorescence detector deadtime variable */
  float DetectorDeadTime	;/* comment out when  Vortex is removed */
  assign DetectorDeadTime "dxpSaturn:mca1.IDTIM"; 

 float DetectorRealTime; 
 assign DetectorRealTime "dxpSaturn:mca1.PRTM"; /* comment out Vortex detector is removed */ 

float PositionerTime;
assign PositionerTime "14IDB:scan1.PDLY";


int StartExScan;
assign StartExScan "{P2}scan1.EXSC";

int AbortExScan;
assign AbortExScan "{P2}AbortScans.PROC";

int ScanNPoints;
assign ScanNPoints to "{P2}scan1.NPTS";

int ScanNPointsRun;
assign ScanNPointsRun to "{P2}scan1.CPT";


int InsertAgFilter;
assign InsertAgFilter to "{P2}DAC1_2.VAL";

int InsertTiFilter;
assign InsertTiFilter to "{P2}DAC1_3.VAL";


int VMirrorDAC;
assign VMirrorDAC to "{P1}DAC1_4.VAL";


/*define variable for the beamstop motor */
double ZBeamstop;
assign ZBeamstop to "{P2}{M3}.VAL";

int ZBeamstopDMOV;
assign ZBeamstopDMOV to "{P2}{M3}.DMOV";


/* define variables for the Detector Z motor */

double ZDetector;
assign ZDetector to "{P2}{M2}.VAL";

int ZDetectorDMOV;
assign ZDetectorDMOV to "{P2}{M2}.DMOV";

/* Shutters */

int AShutterStatus;
assign AShutterStatus to "PA:14ID:A_SHTRS_CLOSED.VAL";
monitor AShutterStatus;
evflag AShutterStatusMon; 
sync AShutterStatus AShutterStatusMon;

int XIAShutterOpen;
assign XIAShutterOpen to "{P2}openXiaShutter.PROC";

int XIAShutterClose;
assign XIAShutterClose to "{P2}closeXiaShutter.PROC";





/* Here define all additional run-time variables needed to run this state notation code */

int count;
int ErrorStatus;
int MonoErrorStatus;
double SavedFlux;
int ScanTimeout;



 


ss IDB_MAD {
 
	state init {
		when() {
		MonoErrorStatus=NO;
		ErrorStatus=NO;
	
		} state monitorInputs 
	} 

    state monitorInputs {
	 when(efTestAndClear(DriveEnergyMon) & (DriveEnergy == 1)) {
	MonoErrorStatus=NO;
        } state DriveEnergy
       when(efTestAndClear(AlignAllMon) & (AlignAll== 1)) {
	ErrorStatus=NO;
        } state AlignAll

	 when(efTestAndClear(CancelAllMon) & (CancelAll== 1)) {
	ErrorStatus=NO;
        } state CancelAll

       when(efTestAndClear(StartEnergyScanMon) & (StartEnergyScan == 1)) {
        } state ScanExEnergy
       when(efTestAndClear(AbortEnergyScanMon) & (AbortEnergyScan == 1)) {
        } state AbortExEnergy 
        
	}

    state DriveEnergy {
	when() {

		pvGet(DesiredEnergy);
		

	/* Check if monochromator is in Auto mode, otherwise display the error message and set the Error  */
	
		pvGet(MonoMode);
		if (MonoMode==AUTO)		
		{


		MonoFeedback=NO;
		VMirrorFeedback=NO;
	
		pvPut(MonoFeedback);			 
		pvPut(VMirrorFeedback);

			MonoEnergy=DesiredEnergy;
			pvPut(MonoEnergy);
			if (DesiredEnergy <= EnGapChange)
			{
			U27=MonoEnergy+GapOffset;
			U23=MaxU23;
			} else
			{
			U23=MonoEnergy+GapOffset;
			U27=MaxU27;
			}
			pvPut(U27);
			pvPut(U23);
			if( MonoEnergyDMOV<1 || U23DMOV<1 || U27DMOV<1 )
 			{
%%			strcpy(pVar->MonoStatus, "Monochromator Moving Energy.");
			pvPut(MonoStatus);
			}

		 
			for (count=0; count<MonoMovingTimeout; count++) {
			epicsThreadSleep(0.5);
			pvGet(MonoEnergyDMOV);
			pvGet(MonoEnergyRBV);
			printf("MonoRBV = %f\n",MonoEnergyRBV);	
			pvGet(U23DMOV);
			pvGet(U27DMOV);
			pvGet(U23RBV);
			printf("U23RBV = %f\n",U23RBV);	
			pvGet(U27RBV);
			printf("U27RBV = %f\n",U27RBV);	
			if ((MonoEnergyDMOV==0) && (abs(MonoEnergyRBV-DesiredEnergy)<0.001) && (abs(U27-U27RBV)<0.002)&& (abs(U23-U23RBV)<0.002))
				{
%%				strcpy(pVar->MonoStatus, "Monochromator Done Moving.");
				pvPut(MonoStatus);
				break;
				}
			}
			if (count>MonoMovingTimeout-2)
			{
%%			strcpy(pVar->MonoStatus, "ERROR:Monochromator Moving Timeout.");
			pvPut(MonoStatus);
			MonoErrorStatus=YES;
			epicsThreadSleep(2);
			}
			if (((abs(U27-U27RBV)>0.002)||(abs(U23-U23RBV)>0.002)))
			{
%%			strcpy(pVar->MonoStatus, "ERROR: Undulator is not at destination.");
			pvPut(MonoStatus);
			}
			count=0;
		}
		else 
		{
%%			strcpy(pVar->MonoStatus, "ERROR:Monochromator Mode is not AUTO.");
			pvPut(MonoStatus);
			MonoErrorStatus=YES;
		}

		MonoFeedback=YES;
		VMirrorFeedback=YES;
	
		pvPut(MonoFeedback);
		epicsThreadSleep(2);			 
		pvPut(VMirrorFeedback);
		DriveEnergy=0;
		pvPut(DriveEnergy);
		epicsThreadSleep(2);

		}state monitorInputs
	}
   


    state AlignAll {
  /*      when(!MonoErrorStatus) {                comment out for testing  */
			 when() {
		pvGet(MonoFlux);
		SavedFlux=MonoFlux;

		MonoFeedback=NO;
		VMirrorFeedback=YES; /* Leave the mirror feedback on for the mono alignment  */

		pvPut(MonoFeedback);                     
		pvPut(VMirrorFeedback);		
/* Put one to busy record for the Align al in the beamCheckMono for DAC and theta alignments */
		AlignMono=YES;
		pvPut(AlignMono);
%%		strcpy(pVar->AlignmentStatus, "Monochromator Aligning.");
		pvPut(AlignmentStatus);

		for (count=0; count < AlignmentTimeout; count++)
		{
		if (CancelAll) 
			{CancelMono=1; 
			pvPut(CancelMono);
			CancelAll=0;
			pvPut(CancelAll);
%%		strcpy(pVar->AlignmentStatus, "Mono Align cancelled by user");
		pvPut(AlignmentStatus);
			break;
			}
		epicsThreadSleep(0.5);
/* periodically checks if status of alignment buttom goes to 0 which indicates the process of alignment is completed . If time is more then timeout it leaves the loop and goves the eroor message */
		if (AlignMono==NO)
		{
		pvGet(MonoAligned);
		{
		if (MonoAligned== YES)
%%		strcpy(pVar->AlignmentStatus, "Monochromator Align Done.");
		if (MonoAligned== NO)
%%		strcpy(pVar->AlignmentStatus, "Monochromator Fail Align.");
		
		}

		pvPut(AlignmentStatus);
		
		epicsThreadSleep(1);
		
		 break;
		}
		}
		if (count>AlignmentTimeout-1)
		{
%%		strcpy(pVar->AlignmentStatus, "ERROR:Monochromator Align Timeout.");
		pvPut(AlignmentStatus);
		ErrorStatus=YES;
		}
		count=0;
		pvGet(MonoAligned);

		/* ---- end of second monochromator alignment */



		if ((AlignMono==NO) & (MonoAligned==YES) & ( !ErrorStatus))
		{


		
	/* proceed with  mirrors alignments if monochromator aligned and there is no error */

	/* verify if BPMs needs to be enabled */

		pvGet(MonoFlux);
		MonoPIDIntMax=MonoFlux;

		pvGet(RingCurrent);
		MonoPIDCurrent=RingCurrent;

		pvPut(MonoPIDCurrent);
		pvPut(MonoPIDIntMax);
		
		pvGet(MirrorFlux);
		SavedFlux=MirrorFlux;

		MonoFeedback=YES;
		VMirrorFeedback=NO;
	
		pvPut(MonoFeedback);
		epicsThreadSleep(12);
/* here might be good to check for the actual readback of the monochromator and give it some more time if needed   */
			 
		pvPut(VMirrorFeedback);			

		epicsThreadSleep(1);
/ * here old settings should be  saved and stored        */
/* rely on beamcheck to save the slis position and to put them back  */
/*		JJVSize=VSLIT;                     */
/*		JJHSize=HSLIT;                      */

/*		pvPut(JJVSize); */
/*		pvPut(JJHSize);  */
		for (count=0; count <AlignmentTimeout; count++)
		{
		epicsThreadSleep(0.1);
		pvGet(JJVSizeDMOV);
		pvGet(JJHSizeDMOV);
		if (JJVSizeDMOV && JJHSizeDMOV) break;
		}

                 DetectorMirrors=KEITHLEY;     /* set detector for mirror alignments - Keithley  */
	      	pvPut(DetectorMirrors);
											
		XIAShutterOpen=1;
		pvPut(XIAShutterOpen);
		epicsThreadSleep(0.5);

 /* why this is done? if any put it to 7 V   */

/*		VMirrorDAC=5;                 */
/*		pvPut(VMirrorDAC);             */

		AlignMirror=YES;
		pvPut(AlignMirror);
%%		strcpy(pVar->AlignmentStatus, "Mirrors Aligning.");
		pvPut(AlignmentStatus);         
		for (count=0; count < AlignmentTimeout; count++)
		{

		if (CancelAll) 
			{
/*			printf("Cancelling Mirrors");		*/
			CancelMirrors=1; 
			pvPut(CancelMirrors);
/*			printf("Putting CancelAll =0");		*/
			CancelAll=0;
			pvPut(CancelAll);
%%		strcpy(pVar->AlignmentStatus, "Mirror Align cancelled by user");
		pvPut(AlignmentStatus);
		XIAShutterClose=1;
		pvPut(XIAShutterClose);
			break;
			}

		epicsThreadSleep(0.5);
		if (AlignMirror==NO)
		{
		pvGet(HMirrorAligned);
		pvGet(VMirrorAligned);
		if ((HMirrorAligned==YES) && (VMirrorAligned==YES))
%%		strcpy(pVar->AlignmentStatus, "Mirrors are aligned. Done.");	
   		if ((HMirrorAligned==YES) && (VMirrorAligned==NO))
%%		strcpy(pVar->AlignmentStatus, "Vert Mirror Fail Align.");		
   		if ((HMirrorAligned==NO) && (VMirrorAligned==YES))
%%		strcpy(pVar->AlignmentStatus, "Horiz Mirror Fail Align.");		
   		if ((HMirrorAligned==NO) && (VMirrorAligned==NO))
%%		strcpy(pVar->AlignmentStatus, "Mirrors Fail Align.");		
		
		XIAShutterClose=1;
		pvPut(XIAShutterClose);		
		pvPut(AlignmentStatus);	
		epicsThreadSleep(1);	
		 break;
		}
		}
		if (count>AlignmentTimeout-1)
		{
%%		strcpy(pVar->AlignmentStatus, "ERROR:Mirrors Aligning Timeout.");
		pvPut(AlignmentStatus);
		ErrorStatus=YES;
		}
		count=0;
		pvGet(MirrorFlux);

	
		pvGet(HMirrorAligned);        
		pvGet(VMirrorAligned);
		
	
		}
	
		if( (VMirrorAligned==YES))
		{

		pvGet(VMirrorPIDF);
		pvGet(VMirrorPIDG);
		VMirrorPIDF=VMirrorPIDF-VMirrorPIDG;
		pvPut(VMirrorPIDF);		
		VMirrorFeedback=YES;

		pvPut(VMirrorFeedback);		
		
		epicsThreadSleep(5);
		XIAShutterClose=1;
		pvPut(XIAShutterClose);

		}
		
		AlignAll=NO;
		pvPut(AlignAll);

/* end of the Alignment procedure here */
		
		} state monitorInputs
	}



state CancelAll {
	when(){
/*	printf("InCacncell All clause"); */
	CancelMono=1;
	pvPut(CancelMono);
	CancelMirrors=1;
	pvPut(CancelMirrors);
	CancelAll=0;
	pvPut(CancelAll);
		} state monitorInputs
	}

 state ScanExEnergy {
	when() {
if 	( MonoEnergyRBV>10.0) {
	InsertAgFilter=0;
	InsertTiFilter=5;
%%	strcpy(pVar->ScanStatus, "Ag filter is inserted");
	pvPut(ScanStatus);
	epicsThreadSleep(1);
	}

if 	( MonoEnergyRBV<=10.0) {
	InsertAgFilter=5;
	InsertTiFilter=0;
%%	strcpy(pVar->ScanStatus, "Ti filter is inserted");
	pvPut(ScanStatus);
	epicsThreadSleep(1);
	}


	pvPut(InsertAgFilter);
	pvPut(InsertTiFilter);
	ZBeamstop=150;
	ZDetector=250;
	pvPut(ZDetector);
%%		strcpy(pVar->ScanStatus, "Detector is Moving to 250mm");
		pvPut(ScanStatus);
		epicsThreadSleep(1);

	pvPut(ZBeamstop);

%%		strcpy(pVar->ScanStatus, "Beamstop is Moving to 120mm");
		pvPut(ScanStatus);
		epicsThreadSleep(1);

	count=0;
%%	do
	{
	epicsThreadSleep(0.01);
	pvGet(ZDetector);
	if (ZDetector==250)
		{
%%		strcpy(pVar->ScanStatus, "Detector is Done Moving");
		pvPut(ScanStatus);
		epicsThreadSleep(1);
		}
	pvGet(ZBeamstop);
	if (ZBeamstop==150)
		{
%%		strcpy(pVar->ScanStatus, "Beamstop is Done Moving");
		pvPut(ScanStatus);
		epicsThreadSleep(1);
		}
	count=count+1;
	if (count>DetectorTimeout) break;
		
	}
%%	while (((pVar->ZDetector)!=250 )&& ((pVar->ZBeamstop)!=150));
	
	if( count> DetectorTimeout)
	{
%%		strcpy(pVar->ScanStatus, "ERROR:Detector/Beamstop moving timeout");
		pvPut(ScanStatus);
		epicsThreadSleep(1);
%%	strcpy(pVar->ScanStatus, "Proceeding with energy scan");
		pvPut(ScanStatus);
		epicsThreadSleep(1);
	}
	
	StartExScan=YES;
	pvPut(StartExScan);
	pvGet(ScanNPoints);
	count=0;
	pvGet(DetectorRealTime);  /*	commented out Vortex is disconnected */ 
	pvGet(PositionerTime);
  %%	pVar->ScanTimeout = pVar->ScanNPoints*(round(pVar->DetectorRealTime+pVar->PositionerTime)+1)+20; /* comm out fruoresc det removed */

/*  %%	pVar->ScanTimeout = pVar->ScanNPoints*(round(1+pVar->PositionerTime)+1)+20;   use this when no Vortex detector */

	printf("ScanTimeout = %i\n",ScanTimeout);

%%	do
	{
	epicsThreadSleep(1);
	pvGet(ScanNPointsRun);
	if (AbortEnergyScan==YES) break;
%%	strcpy(pVar->ScanStatus, "Scanning the energy");
	pvPut(ScanStatus);
	count=count+1;
/*		printf("PointRun = %i\n",ScanNPointsRun);	*/
/*		printf("Total = %i\n",ScanNPoints);		*/

	if( count>ScanTimeout) break;
	}
%%	while ((pVar->ScanNPointsRun)<(pVar->ScanNPoints));
	if (AbortEnergyScan)
	{
	AbortExScan=YES;
	pvPut(AbortExScan);
%%	strcpy(pVar->ScanStatus, "Aborting the scan");
	pvPut(ScanStatus);
	epicsThreadSleep(1);
	AbortEnergyScan=NO;
	pvPut(AbortEnergyScan);
	}
	InsertAgFilter=5;
	InsertTiFilter=0;
%%	strcpy(pVar->ScanStatus, "Ti filter is inserted");
	pvPut(ScanStatus);

	pvPut(InsertTiFilter);
	pvPut(InsertAgFilter);

	epicsThreadSleep(1);
	StartEnergyScan=0;
	pvPut(StartEnergyScan);
%%	strcpy(pVar->ScanStatus, "Done");
	pvPut(ScanStatus);
	
	

		}state monitorInputs
	}
   
 state AbortExEnergy {
	when() {

	InsertAgFilter=5;
	InsertTiFilter=0;
	if (StartEnergyScan==1) AbortExScan=YES;
	pvPut(AbortExScan);
%%	strcpy(pVar->ScanStatus, "Aborting the scan");
	pvPut(ScanStatus);
	epicsThreadSleep(1);
	pvPut(InsertTiFilter);
%%	strcpy(pVar->ScanStatus, "Ti filter is inserted");
	pvPut(ScanStatus);
	pvPut(InsertAgFilter);
	epicsThreadSleep(1);
	AbortEnergyScan=NO;
	pvPut(AbortEnergyScan);
%%	strcpy(pVar->ScanStatus, "Done");
	pvPut(ScanStatus);
	

		}state monitorInputs
	}




}
