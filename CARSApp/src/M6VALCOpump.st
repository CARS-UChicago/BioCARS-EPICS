program M6VALCOpump("P=14LAB:, D=M6:")


%% #include <string.h>
%% #include <stdio.h>
%% #include <stdlib.h>
%% #include <ctype.h>
%% #include <epicsTime.h>
%% #include <time.h>




 option +r;	 		

 option -a; 



/*associate variable with keyword for the serial command to WRITE AND READ*/
string commandOut;
assign commandOut to "{P}{D}SerialWR.AOUT";

string commandIn;
assign commandIn to "{P}{D}SerialWR.TINP";

/*associate variable with keyword for the serial command to WRITE*/
string commandWRITE;
assign commandWRITE to "{P}{D}SerialW.AOUT";



string commandSCANIN;
assign commandSCANIN to "{P}{D}SerialScan.TINP";

string commandSCAN;
assign commandSCAN to "{P}{D}SerialScan.SCAN";

int commandSCANSTAT;
assign commandSCANSTAT to "{P}{D}SerialScan.STAT";



/*associate variable with keyword for Dispensing*/
int Dispense;
assign Dispense to "{P}{D}Dispense.VAL";
monitor Dispense;

/*associate variable with keyword for Dispensing Value*/
float DispenseValue;
assign DispenseValue to "{P}{D}DispenseVal.VAL";

/*associate variable with keyword for Dispensing FlowRate*/
float DispenseFlowRate;
assign DispenseFlowRate to "{P}{D}DispenseFlowRate.VAL";



/*associate variable with keyword for Aspireing*/
int Aspirate;
assign Aspirate to "{P}{D}Aspirate.VAL";
monitor Aspirate;

/*associate variable with keyword for Aspirate Value*/
float AspirateValue;
assign AspirateValue to "{P}{D}AspirateVal.VAL";

/*associate variable with keyword for Aspirate FlowRate */
float AspirateFlowRate;
assign AspirateFlowRate to "{P}{D}AspirateFlowRate.VAL";


/*associate variable with keyword for Washing */
int Wash;
assign Wash to "{P}{D}Wash.VAL";
monitor Wash;

/*associate variable with keyword for Wash Value */
float WashValue;
assign WashValue to "{P}{D}WashVal.VAL";

/*associate variable with keyword for Washing FlowRate */
float WashFlowRate;
assign WashFlowRate to "{P}{D}WashFlowRate.VAL";

/*associate variable with keyword for MotorPosition */
float MotorPos;
assign MotorPos to "{P}{D}MotorPosition.VAL";


/*associate variable with keyword for Abort */
int Abort;
assign Abort to "{P}{D}Abort.VAL";
monitor Abort;


/*associate variable with keyword for Initializing*/
int Initialize;
assign Initialize to "{P}{D}Initialize.VAL";
monitor Initialize;



/*associate variable with keyword for Enabling backlash and monitor it*/
int EnableBacklash;
assign EnableBacklash to "{P}{D}EnableBacklash.VAL";
monitor EnableBacklash;


/*associate variable with keyword for Enabling backlash and monitor it*/
int SetBacklash;
assign SetBacklash to "{P}{D}SetBacklash.VAL";
monitor SetBacklash;



/*associate variable with keyword for backlash Value */
float BacklashVal;
assign BacklashVal to "{P}{D}BacklashVal.VAL";


/*associate variable with keyword for Setting motor position  and monitor it*/
int SetMotorPos;
assign SetMotorPos to "{P}{D}SetMotorPos.VAL";
monitor SetMotorPos;



/*associate variable with keyword for Motor Position Value */
float MotorPosVal;
assign MotorPosVal to "{P}{D}MotorPosVal.VAL";




/*associate variable with keyword for the motor Calibration*/
int Calibrate;
assign Calibrate to "{P}{D}Calibrate.VAL";
monitor Calibrate;

/*associate variable with keyword for Motor Volume Per Revolution Value Request */
float VolPerRevValReq;
assign VolPerRevValReq to "{P}{D}VolPerRevValReq.VAL";

/*associate variable with keyword for Volume Per Revolution Value */
float VolumePerRevVal;
assign VolumePerRevVal to "{P}{D}VolumePerRevVal.VAL";

/*associate variable with keyword for the ERROR_STRING*/
string ERRORSTRING;
assign ERRORSTRING to "{P}{D}ERROR_STRING.VAL";


/*associate variable with keyword for the ERROR_STRING*/
string STATUSSTRING;
assign STATUSSTRING to "{P}{D}STATUS_STRING.VAL";




/*set the event flag upon the monitor event delivery*/
evflag DispenseFlag;
sync Dispense DispenseFlag;

evflag AspirateFlag;
sync Aspirate AspirateFlag;

evflag WashFlag;
sync Wash WashFlag;

evflag AbortFlag;
sync Abort AbortFlag;


evflag InitializeFlag;
sync Initialize InitializeFlag;

evflag EnableBacklashFlag;
sync EnableBacklash EnableBacklashFlag;

evflag SetBacklashFlag;
sync SetBacklash SetBacklashFlag;

evflag CalibrateFlag;
sync Calibrate CalibrateFlag;

evflag SetMotorPosFlag;
sync SetMotorPos SetMotorPosFlag;


int Operate;

float VolumeValue;			/*holds Dispense/Aspire Wash etc value*/
float FlowRate;			/*holds Dispense/Aspire Wash etc FlowRate value*/
int Status;
int BacklashStatus;

string  temp;
string FLOW;
string OUT;
string IN;


/*first  state set (each state is a thread)*/



ss M6VALCOpump {

	/*initialization procedures and values*/

	state init{

	    when(){

	strcpy(temp,"Passive");
		%%         strcpy(pVar->commandSCAN,pVar->temp);
		pvPut(commandSCAN); 	
epicsThreadSleep(0.1);
	/*	printf("Inilialize");  */
		strcpy(temp,"ECHO=2"); 
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);

epicsThreadSleep(0.1);
		strcpy(temp,"VI=0.001");
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);
	

		strcpy(temp,"VM=20");
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);

			strcpy(temp,"PRINT POS");
			%%         strcpy(pVar->commandOut,pVar->temp);
	epicsThreadSleep(0.1);
			pvPut(commandOut);
	epicsThreadSleep(0.1);
			pvGet(commandIn);
			MotorPos=atof(commandIn);
			pvPut(MotorPos);
	
			strcpy(temp,"PRINT BLSH");
			%%         strcpy(pVar->commandOut,pVar->temp);
	epicsThreadSleep(0.1);
			pvPut(commandOut);
	epicsThreadSleep(0.1);
			pvGet(commandIn);
			BacklashVal=atof(commandIn);
			pvPut(BacklashVal);

	
			

			}state start

			}

	state start {
	


	when (efTestAndClear( DispenseFlag )){ 

/*	printf("Dispense"); */

		if ((Dispense))
		{

/* obtain the FlowRate Value and set MAX VELO of the motor to thie value/60, ul/sec */
			pvGet(DispenseFlowRate);
			FlowRate=DispenseFlowRate/60;
	
/* obtain the Desired Misplacement Value and set MOVR in uL */
			pvGet(DispenseValue);
			VolumeValue=DispenseValue;

			Operate=1;	
		}
	
		} state start



	when (efTestAndClear( AspirateFlag )){ 

/*	printf("Aspirate"); */

		if ((Aspirate))
		{

/* obtain the FlowRate Value and set MAX VELO of the motor to thie value/60, ul/sec */
			pvGet(AspirateFlowRate);
			FlowRate=AspirateFlowRate/60;
	
/* obtain the Desired Misplacement Value and set MOVR in uL */
			pvGet(AspirateValue);
			VolumeValue=-AspirateValue;
			Operate=1;	
		}
	

		} state start


	when (efTestAndClear( WashFlag )){ 

/*	printf("Wash");  */

		if ((Wash))
		{

/* obtain the FlowRate Value and set MAX VELO of the motor to thie value/60, ul/sec */
			pvGet(WashFlowRate);
			FlowRate=WashFlowRate/60;
	
/* obtain the Desired Misplacement Value and set MOVR in uL */
			pvGet(WashValue);
			VolumeValue=WashValue;
			Operate=1;	
		}
	
		
		} state start









	when (Operate){ 

/*	printf("Operate"); */
		{

/* obtain the FlowRate Value and set MAX VELO of the motor to thie value/60, ul/sec */
	
		sprintf(OUT, "%f", FlowRate);
		strcpy(temp,"VM=");

		strcat(temp,OUT);
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);

epicsThreadSleep(0.1);

/* obtain the Desired Misplacement Value and set MOVR in uL */
		
		sprintf(OUT, "%f", VolumeValue);
		strcpy(temp,"MOVR ");

		strcat(temp,OUT);
		%%         strcpy(pVar->commandWRITE,pVar->temp);
/* printf("%s", commandWRITE); */
		pvPut(commandWRITE);
/* changed 0.1 instead of 1 sec */
	epicsThreadSleep(0.1);

/* check for the motion to complete: set scanning field of commandSCAN to .1sec */
/* when commandSCANIN  give FALSE, the motion is complete   */
		strcpy(temp,".1 second");
		%%         strcpy(pVar->commandSCAN,pVar->temp);
		pvPut(commandSCAN);	
		strcpy(temp,"TRUE");
			
 %%			do
			{
/*	printf("Do"); */
			
			
					strcpy(temp,"PRINT POS");
					%%         strcpy(pVar->commandOut,pVar->temp);
					pvPut(commandOut);
					epicsThreadSleep(0.1);
					pvGet(commandIn);
					MotorPos=atof(commandIn);

/* printf("%s", commandIn); */
					pvPut(MotorPos);
			
			pvGet(commandSCANIN);
			if(Abort) break;
			strcpy(temp,"TRUE");
			pvGet(commandSCANSTAT);

			}
		
%%		while ((strcmp(pVar->commandSCANIN,pVar->temp)==0)&(pVar->commandSCANSTAT==0));  

 /*	printf("Pass the loop");        */


	strcpy(temp,"PRINT POS");
					%%         strcpy(pVar->commandOut,pVar->temp);
					pvPut(commandOut);
					epicsThreadSleep(0.1);
					pvGet(commandIn);
					MotorPos=atof(commandIn);

 /*  printf("%s", commandIn);  */
					pvPut(MotorPos);

		
		strcpy(temp,"Passive");
		%%         strcpy(pVar->commandSCAN,pVar->temp);
/*		pvPut(commandSCAN); Do not put back in passive mode yet  */	
		Operate=0;
		if(Dispense==1)
			{Dispense=0;
			pvPut(Dispense);
			}
		if(Aspirate==1)
			{Aspirate=0;
			pvPut(Aspirate);
			}
		if(Wash==1)
			{Wash=0;
			pvPut(Wash);
			}
		
		}
		
		} state start



			when (efTestAndClear( SetMotorPosFlag )){ 
		     
/*	printf(" Set MotorPosition");  */
	if (SetMotorPos)
				{
				 pvGet(MotorPosVal);
				sprintf(OUT, "%f", MotorPosVal);
				strcpy(temp,"POS=");
				strcat(temp,OUT);
				%%         strcpy(pVar->commandWRITE,pVar->temp);
				pvPut(commandWRITE);
	epicsThreadSleep(0.1);
		
			strcpy(temp,"PRINT POS");
		%%         strcpy(pVar->commandOut,pVar->temp);
		pvPut(commandOut);
		epicsThreadSleep(0.1);
		pvGet(commandIn);
		MotorPos=atof(commandIn);
		pvPut(MotorPos);

	SetMotorPos=0;
	pvPut(SetMotorPos);

			}



            } state start






			when (efTestAndClear( SetBacklashFlag )){ 
		     
/*	printf(" Set backlash");  */
	if (SetBacklash)
				{
				 pvGet(BacklashVal);
				sprintf(OUT, "%f", BacklashVal);
				strcpy(temp,"BLSH=");
				strcat(temp,OUT);
				%%         strcpy(pVar->commandWRITE,pVar->temp);
				pvPut(commandWRITE);
		
			strcpy(temp,"PRINT BLSH");
		%%         strcpy(pVar->commandOut,pVar->temp);

	epicsThreadSleep(0.1);
		pvPut(commandOut);
	epicsThreadSleep(0.1);
		pvGet(commandIn);
		BacklashVal=atof(commandIn);
		pvPut(BacklashVal);

	SetBacklash=0;
	pvPut(SetBacklash);

			}



            } state start



			when (efTestAndClear( EnableBacklashFlag )){ 
		     
/*	printf("backlash");  */

				{

		strcpy(temp,"BLE=");
		Status=EnableBacklash;
			if (Status==0)
				{BacklashStatus=1;

				
				}
			else BacklashStatus=0;
		strcpy(temp,"BLE=");
		sprintf(OUT, "%i", BacklashStatus);
		strcat(temp,OUT);
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);

			}


            } state start



			when (efTestAndClear( InitializeFlag )){ 
/*	printf("Initialize op");  */
		if(Initialize==1)
		    		
			{


	strcpy(temp,"Passive");
		%%         strcpy(pVar->commandSCAN,pVar->temp);
		pvPut(commandSCAN); 	
		epicsThreadSleep(0.1);

		strcpy(temp,"ECHO=2");
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);
	
	epicsThreadSleep(0.1);
		strcpy(temp,"VI=0.001");
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);
	

		strcpy(temp,"VM=20");
		%%         strcpy(pVar->commandWRITE,pVar->temp);
		pvPut(commandWRITE);

		strcpy(temp,"PRINT POS");
		%%         strcpy(pVar->commandOut,pVar->temp);
	epicsThreadSleep(0.1);
		pvPut(commandOut);
	epicsThreadSleep(0.1);
		pvGet(commandIn);
		MotorPos=atof(commandIn);
		pvPut(MotorPos);
		
		strcpy(temp,"PRINT BLSH");
		%%         strcpy(pVar->commandOut,pVar->temp);
	epicsThreadSleep(0.1);
		pvPut(commandOut);
	epicsThreadSleep(0.1);
		pvGet(commandIn);
		BacklashVal=atof(commandIn);
		pvPut(BacklashVal);
	

		}

		Initialize=0;
		pvPut(Initialize);

		} state init



	when (efTestAndClear( CalibrateFlag )){ 
		if(Calibrate)
/*	printf("calibrate");  */		    		
			{
/*		pvGet(VolPerRevValReq);
		VolumeValue=256*950/VolPerRevValReq;
				sprintf(OUT, "%f", VolumeValue);
				strcpy(temp,"MUNIT=");
				strcat(temp,OUT);
				%%         strcpy(pVar->commandWRITE,pVar->temp);
				pvPut(commandWRITE);
		
		strcpy(temp,"PRINT MUNIT");
		%%         strcpy(pVar->commandOut,pVar->temp);
	epicsThreadSleep(0.1);
		pvPut(commandOut);
	epicsThreadSleep(0.1);
		pvGet(commandIn);
		VolumePerRevVal=atof(commandIn);

		pvPut(VolumePerRevVal);
*/		
			}
		Calibrate=0;
		pvPut(Calibrate);

            } state start


	when (efTestAndClear(AbortFlag )){ 
/*		printf("Abort");   */	   
		if(Abort==1)
		    		
			{
			strcpy(temp,"REQUEST TO ABORT. ABORT OPERATIONS");
			%%         strcpy(pVar->STATUSSTRING,pVar->temp);
			pvPut(STATUSSTRING);

				strcpy(temp,"SSTP");
			%%         strcpy(pVar->commandWRITE,pVar->temp);
			pvPut(commandWRITE);   
			epicsThreadSleep(1);
	
		strcpy(temp,"PRINT POS");	

		%%         strcpy(pVar->commandOut,pVar->temp);

	epicsThreadSleep(0.1);
		pvPut(commandOut);

	epicsThreadSleep(0.1);
		pvGet(commandIn);
		MotorPos=atof(commandIn);		

		pvPut(MotorPos);
			
		
			}

		Abort=0;
		pvPut(Abort);

            } state start 

	}

}