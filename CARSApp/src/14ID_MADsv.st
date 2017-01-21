program 14ID_MAD("P1=14IDA:, P2=14IDB:, P3=IDC:,  M1=m12, M2=m3, M3=m8, M4=m27, M5=m25")

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
assign AlignMono to "{P2}beamCheckMDT";
monitor AlignMono;
evflag AlignMonoMon; 
sync AlignMono AlignMonoMon;
 

/* Define variable to check Monochromator alignment status */
int MonoAligned;
assign MonoAligned to "{P2}beamCheckMAln"; /* add to the beam Check Mono */


/* Define variables for using combined Theta motor and DAC for optimizing mirrors */
int AlignMirror;
assign AlignMirror to "{P2}beamCheckComb";
monitor AlignMirror;
evflag AlignMirrorMon; 
sync AlignMirror AlignMirrorMon;
 

/* Define variable to check Vertical mirror alignment status */
int VMirAligned;
assign VMirAligned to "{P2}beamCheckVAln";   /* add to the beamCheck */


/* Define variable to check Horizontal mirror alignment status */
int HMirAligned;
assign HMirAligned to "{P2}beamCheckHAln";   /* add to the beamCheck */


/* Define variable to get the Flux value for the Monochromator alignment */
double MonoFlux;
assign MonoFlux to "{P2}EM1Sum2.VAL";

/* Define variable to get the Flux Value for mirror alignment */
double MirrorFlux;
assign MirrorFlux to "{P2}Keithley:AcqTotalInv.VAL";


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
int AlignAll;
assign CancelAll to "{P2}CancelAlignment.VAL";
monitor CancelAll;
evflag CancelAllMon; 
sync CancelAll CancelAllMon;


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


/ * Define variables for turning off and on feedback for the alignment purposes */

/* Define variable to turn on and off monochromator feedback */
int MonoFeedback;
assign MonoFeedback "{P1}mono_pid1.FBON";

/* Define synchrotron Ring current for Mono PID calculations */
double RingCurret;
assign RingCurrent "S:SRcurrentAI.VAL";


/* Define Monochromator PID Max Current in calc  for feedback calculations */
double MonoPIDIntMax;
assign MonoPIDIntMax to "{P1}mono_pid1_incalc.F";

/* Define Monochromator PID Ring Current in calc  for feedback calculations */
double MonoPIDCurrent;
assign MonoPIDCurrent to "{P1}mono_pid1_incalc.E";

/* Define variable to turn on and off Vertical mirror feedback */
int MonoFeedback;
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
double MonoEnergyRDBK;
assign MonoEnergyRDBK to "{P1}BraggEAO.DRVH";

/* Define variable to read back  Monochromator Energy - verify this field*/
double MonoEnergyDMOV;
assign MonoEnergyDMOV to "{P1}KohzuMoving";



/* Define variable to Drive U27 */
double U27;
assign U27 to "{P1}U27Eng.VAL";

/* Define variable to DMOV  U27 */
int U27DMOV;
assign U27DMOV to "{P1}U27Eng.DMOV";

/* Define readback variable */
int U27RBV;
assign U27RBV to "{P1}U27Eng.SET";





/* Define variable to Drive U23 */
double U23;
assign U23 to "{P1}U23Eng.VAL";


/* Define variable to readback U23 */
int U23DMOV;
assign U23DMOV to "{P1}U23Eng.DMOV";

/* Define readback variable */
int U23RBV;
assign U23RBV to "{P1}U23Eng.SET";






/* Define PV's to Scan the energy */

/ * define variables to interface with MEDM screen for run/abort Energy Scans */

int StartEnergyScan;
assign StartEnergyScan to "{P2}StartScan.VAL";
monitor StartEnergyScan;
evflag StartEnergyScanMon; 
sync StartEnergyScan StartEnergyScanMon;

int AbortEnergyScan;
assign AbortEnergyScan to "{P2}AbortScan";
monitor AbortEnergyScan;
evflag AbortEnergyScanMon; 
sync AbortEnergyScan StartEnergyScanMon;

/ * define interface to execute or abort scan1 energy scans */
 
int StartExScan;
assign StartExScan "{P2}scan1.EXSC";

int AbortExScan;
assign AbortExScan "{P2}AbortScans.PROC";

int ScanNPoints;
assign ScanNPoints to "{P2}scan1.NPTS";

int ScanNPointsRun;
assign ScanNPointsRun to "{P2}scan1.CPT;

/* Define PV to insert the filters */
int InsertAgFilter;
assign InsertAgFilter to "{P2}DAC1_2.VAL";

int InsertTiFilter;
assign InsertTiFilter to "{P2}DAC1_3.VAL";

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

int AShutterStatus;
assign AShutterStatus to "PA:14ID:A_SHTRS_CLOSED.VAL"
monitor AShutterStatus;
evflag AShutterStatusMon; 
sync AShutterStatus AShutterStatusMon;



/* Here define all additional run-time variables needed to run this state notation code */

int count;
int ErrorStatus;
double SavedFlux;




#define EnGapChange=17.000;
#define GapOffset=0.150;
#define MaxU23=21.000;
#define MaxU27=17.200;
#define MonoMovingTimeout=600;
#define MinSRCurrent=50.00;
#define YES=1;
#define NO=0;
#define AlignmentTimeout=300;
#define KEITHLEY=1;
#define VSLIT=0.07;
#define HSLIT=0.14;

 


ss 14ID_MAD{
 
	state init {
		when() {
	
		} state monitorInputs 
	} 

    state monitorInputs {
	 when(efTestAndClear(DriveEnergyMon) & (DriveEnergy == 1)) {
	ErrorStatus=NO;
        } state DriveEnergy
       when(efTestAndClear(AlignAllMon) & (AlignAll== 1)) {
	ErrorStatus=NO;
        } state AlignAll

       when(efTestAndClear(StartExScanMon) & (StartExScan == 1)) {
        } state StartExScan
       when(efTestAndClear(AbortExScanMon) & (AbortExScan == 1)) {
        } state AbortExScan 
        
	}

    state DriveEnergy {
	when() {

		pvGet(DesiredEnergy);
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
%%		strcpy(pVar->AlignmentStatus, "Monochromator Moving Energy.");
		pvPut(AlignmentStatus);
		}

		 
		for (count=0; count<MonoMovingTimeout; count++) {
		epicsThreadSleep(0.5);
		pvGet(MonoEnergyDMOV);
		pvGet(MonoEnergyRBV);
		pvGet(U23DMOV);
		pvGet(U27MOV);
		pvGet(U23RBV);
		pvGet(U27RBV);
		if ((MonoEnergyDMOV>0)&&(U23DMOV>0) && (U27DMOV>0) && (abs(MonoEnergyRBV-DesiredEnergy)<0.001) && (abs(U27-U27RBV)<0.01)&& (abs(U23-U23RBV)<0.01))
		{
%%		strcpy(pVar->AlignmentStatus, "Monochromator Done Moving.");
		pvPut(AlignmentStatus);
		break;
		}
		}
		if (count>MonoMovingTimeout-1)
		{
%%		strcpy(pVar->AlignmentStatus, "ERROR:Monochromator Moving Timeout.");
		pvPut(AlignmentStatus);
		ErrorStatus=YES;
		}
		count=0;
		DriveEnergy=0;
		pvPut(DriveEnergy);

		}state monitorInputs
	}
   


    state AlignAll {
        when() {
		pvGet(MonoFlux);
		SavedFlux=MonoFlux;

		MonoFeedback=NO;
		VMirrorfeedback=YES; /* Leave the mirror feedback on for the mono alignment  */

		pvPut(MonoFeedback);
		pvPut(VMirrorFeedback);
/* Put one to busy record for the Align al in the beamCheckMono for DAC and theta alignments */
		AlignMono=YES;
		pvPut(AlignMono);
%%		strcpy(pVar->AlignmentStatus, "Monochromator Aligning.");
		pvPut(AlignmentStatus);

		for (count=0; count < AlignmentTimeout; count++)
		{
		epicsThreadSleep(0.5);
/* periodically checks if status of alignment buttom goes to 0 which indicates the process of alignment is completed . If time is more then timeout it leaves the loop and goves the eroor message */
		if (AlignMono==NO)
		{
		pgGet(MonoAligned);
		{
		if (MonoAlinged== YES)
%%		strcpy(pVar->AlignmentStatus, "Monochromator Align Done.");
		if (MonoAlinged== NO)
%%		strcpy(pVar->AlignmentStatus, "Monochromator still not aligned.");
		}

		pvPut(AlignmentStatus);
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



		if (AlingMono==NO & MonoAligned==YES & !ErrorStatus)
		{
	/* proceed with  mirrors alignments if monochromator aligned and there is no error */

	/* verify if BPMs needs to be enabled */

		pvGet(MonoFlux);
		MonoPIDIntFlux=MonoFlux;

		pvGet(RingCurrent);
		MonoPIDCurrent=RingCurrent;

		pvPut(MonoPIDCurrent);
		pvPut(MonoPIDIntFlux);
		
		pvGet(MirrorFlux);
		SavedFlux=MirrorFlux;

		Monofeedback=YES;
		VMirrorfeedback=NO;

		pvPut(MonoFeedback);
		pvPut(VMirrorFeedback);

		JJVSize=VSLIT;
		JJHSize=HSLIT;

		pvPut(JJVSize);
		pvPut(JJHSize);
		for (count=0; count <AlignmentTimeout; count++)
		{
		epicsThhhreadSleep(0.1);
		pvGet(JJVSizeDMOV);
		pvGet(JJHSizeDMOV);
		if (JJVSizeDMOV && JJHSizeDMOV) break;
		}

                MirrorDetector=KEITHLEY;     /* set detector for mirror alignments - Keithley  */
	      	pvPut(MirrorDetector);

		AlignMirror=YES;
		pvPut(AlignMirror);
%%		strcpy(pVar->AlignmentStatus, "Mirrors Aligning.");
		pvPut(AlignmentStatus);         
		for (count=0; count < AlignmentTimeout; count++)
		{
		epicsThreadSleep(0.5);
		if (AlignMirror==NO)
		{
		pvGet(HMirrorAligned);
		pvGet(VMirrorAligned);
		if (HMirrorAligned==YES && (VMirrorAligned==YES))
%%		strcpy(pVar->AlignmentStatus, "Mirrors are aligned");	
   		if (HMirrorAligned==YES && (VMirrorAligned==NO))
%%		strcpy(pVar->AlignmentStatus, "Vert Mirror still not  aligned.");		
   		if (HMirrorAligned==NO && (VMirrorAligned==YES))
%%		strcpy(pVar->AlignmentStatus, "Horiz Mirror still not  aligned.");		
   		if (HMirrorAligned==NO && (VMirrorAligned==NO))
%%		strcpy(pVar->AlignmentStatus, "Mirrors still not  aligned.");		
				
		pvPut(AlignmentStatus);		
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
		
		
		}
		
		AlingAll=NO;
		pvPut(AlignAll);

/* end of the Alignment procedure here */
		
		} state monitorInputs
	}





 state ScanExEnergy {
	when() {

	InsertAgFilter=YES;
	InsertTiFilter=YES;

	pvPut(InsertAgFilter);
	pvPut(InsertTiFilter);
	ZBeamstop=150;
	ZDetector=250;
	pvPut(ZDetector);
	pvPut(ZBeamstop);

	do
	{
	epicsThreadSleep(0.1);
	pvGet(ZDetectorDMOV);
	pvGet(ZBeamstopDMOV);
	}
	while (!ZDetectorDMOV && !ZBeamstopDMOV);
	
	StartExScan=YES;
	pvPut(StartExScan);
	pvGet(ScanNPoints);
	do
	{
	epicsThreadSleep(0.1);
	pvGet(ScanNPointsRun);
	if (AbortEnergyScan==YES) break;
	}
	while (ScanNPointsRun<ScanNPoints);
	if (AbortEnergyScan)
	{
	AbortExScan=YES;
	pvPut(AbortExScan);
	AbortEnergyScan=NO;
	pvPut(AbortEnergyScan);
	}
	InsertAgFilter=NO;
	InsertTiFilter=NO;
	pvPut(InsertAgFilter);
	pvPut(InsertTiFilter);
	
	
	

		}state monitorInputs
	}
   
 state AbortExEnergy {
	when() {

	InsertAgFilter=NO;
	InsertTiFilter=NO;
	if (StartEnergyScan==1) AbortExScan=YES;
	pvPut(AbortExScan);
	pvPut(InsertAgFilter);
	pvPut(InsertTiFilter);
	AbortEnergyScan=NO;
	pvPut(AbortEnergyScan);
	

		}state monitorInputs
	}




}
