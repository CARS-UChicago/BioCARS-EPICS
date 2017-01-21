program keithley6485st("P=14LAB:, R=Keithley1:")

/* This program monitors variable supplied by Keithley6485St.Db */
/* it reads current, find max and min inthe current set and change the Keithley 6485 settings */


%% #include <string.h>
%% #include <stdio.h>
%% #include <stdlib.h>
%% #include <ctype.h>
%% #include <epicsTime.h>
%% #include <time.h>


#define MAX_LEN 250

 option +r;	 		

 option -a; 


/*associate variable with serial port read Pv  14Cygwin:Keithley and monitor it*/
char currentInp[MAX_LEN];
assign currentInp to "{P}{R}READ_CURR.BINP"; 
monitor currentInp;
/*associate variable with keyword for the serial command to WRITE AND READ*/
string commandOut;
assign commandOut to "{P}{R}READ_CURR.AOUT";

/*associate variable with keyword for Starting Acquisition and monitor it*/
int Acquire;
assign Acquire to "{P}{R}Start.PROC";
monitor Acquire;

/*associate variable with keyword for Monitoring Current and monitor it*/
int MonitorCur;
assign MonitorCur to "{P}{R}Monitor.VAL";
monitor MonitorCur;

/*associate variable with keyword for Stop Monitoring Current and monitor it*/
int StopMonitorCur;
assign StopMonitorCur to "{P}{R}StopMonitor.VAL";
monitor StopMonitorCur;

/*associate variable with keyword for Serial Port Scanning and monitor it*/
string ScanSerial;
assign ScanSerial to "{P}{R}READ_CURR.SCAN";
monitor ScanSerial;

/*associate variable with keyword for Device Initialization and monitor it*/
string InitDev;
assign InitDev to "{P}{R}INIT_DEV.VAL";
monitor InitDev;

/*associate variable with keyword for Selecting Range of Device and monitor it*/
string SelectGain;
assign SelectGain to "{P}{R}SelectGain.VAL";
monitor SelectGain;

/*associate variable with keyword for Selecting Averaging of Device and monitor it*/
int SelectAvg;
assign SelectAvg to "{P}{R}SelectAvrgOn.VAL";
monitor SelectAvg;

/*associate variable with keyword for Selecting Filtering of Device and monitor it*/
string SelectFilter;
assign SelectFilter to "{P}{R}SelectFilter.VAL";
monitor SelectFilter;

/*associate variable with keyword for Selecting Counting of Device Filter and monitor it*/
string SelectFilterCn;
assign SelectFilterCn to "{P}{R}SlctFltCn.VAL";
monitor SelectFilterCn;

/*associate variable with keyword for Selecting Averaging of Device and monitor it*/
string SelectMed;
assign SelectMed to "{P}{R}SelectMedOn.VAL";
monitor SelectMed;

/*associate variable with keyword for Selecting Counting of Device Filter and monitor it*/
string SelectMedCn;
assign SelectMedCn to "{P}{R}SlctMedRank.VAL";
monitor SelectMedCn;

/*associate variable with keyword for Enabling Zero Check of Device and monitor it*/
int SelectZrCkOn;
assign SelectZrCkOn to "{P}{R}SelectZrCkOn.VAL";
monitor SelectZrCkOn;


/*associate variable with keyword for Enabling Zero Correct of Device and monitor it*/
int SelectZrCrOn;
assign SelectZrCrOn to "{P}{R}SelectZrCrOn.VAL";
monitor SelectZrCrOn;


/*associate variable with keyword for Acquiring Zero Correct of Device and monitor it*/
int ZeroCrIn;
assign ZeroCrIn to "{P}{R}ZEROCR_IN.PROC";
monitor ZeroCrIn;


/*associate variable with keyword for Resetting of Device and monitor it*/
int Rst;
assign Rst to "{P}{R}RESET.PROC";
monitor Rst;




/*associate variable with keyword for Busy status */
int Busy;
assign Busy to "{P}{R}BusyAcq.VAL";

/*associate variable with keyword for the Number Samples to Collect */
int AcqNumS;
assign AcqNumS to "{P}{R}AcqNumS.VAL";


/*associate variable with keyword for Busy status */
int Auto;
assign Auto to "{P}{R}SelectAutoOn.VAL";


/*associate variable with keyword for Acquisition Total Current value*/
float AcqTotal;
assign AcqTotal to "{P}{R}AcqTotal.VAL";

/*associate variable with keyword for Min Acquisition  value*/
float AcqMin;
assign AcqMin to "{P}{R}AcqMin.VAL";

/*associate variable with keyword for Max Acquisition  value*/
float AcqMax;
assign AcqMax to "{P}{R}AcqMax.VAL";


/*associate variable with keyword for the serial command to WRITE ONLY*/
string writeOut;
assign writeOut to "{P}{R}WRITE.AOUT";




float current;			/*holds cumulative current value*/
float StatsCurrent[2];		/*holds Min and Max current over specified number of samples*/
char *commands[25];            /*holds list of commands utilized in the program*/

/*set the event flag upon the monitor event delivery*/
evflag currentInpFlag;
sync currentInp currentInpFlag;

evflag AcquireFlag;
sync Acquire AcquireFlag;

evflag MonitorCurFlag;
sync MonitorCur MonitorCurFlag;

evflag StopMonitorCurFlag;
sync StopMonitorCur StopMonitorCurFlag;


evflag InitDevFlag;
sync InitDev InitDevFlag;

evflag SelectGainFlag;
sync SelectGain SelectGainFlag;

evflag SelectAvgFlag;
sync SelectAvg SelectAvgFlag;

evflag SelectFilterFlag;
sync SelectFilter SelectFilterFlag;

evflag SelectFilterCnFlag;
sync SelectFilterCn SelectFilterCnFlag;

evflag SelectMedFlag;
sync SelectMed SelectMedFlag;

evflag SelectMedCnFlag;
sync SelectMedCn SelectMedCnFlag;

evflag SelectZrCkOnFlag;
sync SelectZrCkOn SelectZrCkOnFlag;


evflag SelectZrCrOnFlag;
sync SelectZrCrOn SelectZrCrOnFlag;

evflag ZeroCrInFlag;
sync ZeroCrIn ZeroCrInFlag;

evflag RstFlag;
sync Rst RstFlag;






/*string management*/

char *temp;
char *tempNum;
char NumberOfSamples[5];
char TempCommand[40];
char buffer[MAX_LEN]; 


char ZeroString[40];



/* int k=0;		*/ 							


/*	string ZeroString;	 */ 






/*Declare the C functions, use escape sequence*/
%{
void GetString(char *StrSource, char *StrDest, int St, int Fin);

void GetCopy(char StrSource[], char *chararray);

float GetCurrent(char *StrSource, float StatsDest[], int Num);

}%


/*first  state set (each state is a thread)*/



ss keithley6485st {

	/*initialization procedures and values*/

	state init{

	    when(){

StatsCurrent[0]=0;
StatsCurrent[1]=0;
commands[0]="CONF:CURR";
commands[1]="FORM:ELEM READ"; 
commands[2]="READ?";
commands[3]="TRIG:COUN ";
commands[4]="CURR:RANG ";
commands[5]="AVER ";
commands[6]="AVER:TCON ";
commands[7]="AVER:COUN ";
commands[8]="SYST:ZCH ";
commands[9]="SYST:ZCOR ";
commands[10]="INIT";
commands[11]="SYST:ZCOR:ACQ";
commands[12]="*RST";
commands[13]="Passive";
commands[14]=".2 second";
commands[15]="CURR:NPLC 1";
commands[16]="MED ";
commands[17]="MED:RANK ";





			}state start
		/*end initialization*/
			}

	/*initial state*/
	state start {
	
	/*report current on change*/
	/*when (efTestAndClear( currentInpFlag )){*/

	when (efTestAndClear( AcquireFlag )){ 



		if (Acquire==1)
		{
/* stop Current Monitor */


		MonitorCur=0;
		pvPut(MonitorCur);

/* Put SCAN in PASSIVE mode */

		temp=commands[13];
		strcpy(ScanSerial,temp);
		pvPut(ScanSerial);

/* Obtain number of samples to collect current */

		pvGet(AcqNumS);
		sprintf(NumberOfSamples, "%d", AcqNumS);
		temp=commands[3];
		strcpy(TempCommand,temp);
		tempNum=NumberOfSamples;
		strcat(TempCommand,NumberOfSamples);
		strcpy(writeOut,TempCommand);
		pvPut(writeOut,SYNC);
/* Obtain reading */
		temp=commands[2];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);



	
		}
		
		} state start

       

			when (efTestAndClear( InitDevFlag )){ 
		    		
			{

		temp=commands[0];
		strcpy(writeOut,temp);
		pvPut(writeOut,SYNC);
		temp=commands[1];
		strcpy(writeOut,temp);
		pvPut(writeOut,SYNC);

		AcqNumS=1;
		pvPut(AcqNumS);
		SelectZrCkOn=0;
		pvPut(SelectZrCkOn);
		Auto=1;			
		pvPut(Auto);		
		

		temp=commands[2];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);


			}


            } state start


when (efTestAndClear( SelectGainFlag )){ 
		     
				{

		temp=commands[4];
		strcpy(TempCommand,temp);
		strcat(TempCommand,SelectGain);

		strcpy(writeOut,TempCommand);
		pvPut(writeOut,SYNC);

		Auto=0;			
		pvPut(Auto);		
		
		temp=commands[2];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);


			}


            } state start

when (efTestAndClear( SelectAvgFlag )){ 
		   
				{

		temp=commands[5];
		strcpy(TempCommand,temp);

		sprintf(ZeroString, "%d", SelectAvg);
		
		strcat(TempCommand,ZeroString);

		strcpy(writeOut,TempCommand);

		pvPut(writeOut,SYNC);
	

			}


            } state start

when (efTestAndClear( SelectFilterFlag )){ 
		    
				{

		temp=commands[6];
		strcpy(TempCommand,temp);
		strcat(TempCommand,SelectFilter);

		strcpy(writeOut,TempCommand);
		pvPut(writeOut,SYNC);



			}


            } state start


when (efTestAndClear( SelectFilterCnFlag )){ 
		     

				{
		temp=commands[7];
		strcpy(TempCommand,temp);
		strcat(TempCommand,SelectFilterCn);

		strcpy(writeOut,TempCommand);
		pvPut(writeOut,SYNC);
		temp=commands[2];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);


			}


            } state start

/*  Median Filter */


when (efTestAndClear( SelectMedCnFlag )){ 
		     

				{
		temp=commands[17];
		strcpy(TempCommand,temp);
		strcat(TempCommand,SelectMedCn);

		strcpy(writeOut,TempCommand);
		pvPut(writeOut,SYNC);
		


			}


            } state start

when (efTestAndClear( SelectMedFlag )){ 
		   
				{

		temp=commands[16];
		strcpy(TempCommand,temp);
		strcat(TempCommand,SelectMed);

		strcpy(writeOut,TempCommand);
		pvPut(writeOut,SYNC);
		

			}


            } state start






when (efTestAndClear( SelectZrCkOnFlag )){ 
		    
				{


		temp=commands[8];

	
		strcpy(TempCommand,temp);
		
		sprintf(ZeroString, "%d", SelectZrCkOn);
		
		strcat(TempCommand,ZeroString);

		strcpy(writeOut,TempCommand);
		pvPut(writeOut);
		temp=commands[2];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);


			}


            } state start


when (efTestAndClear( SelectZrCrOnFlag )){ 
		    				{

		temp=commands[9];

		strcpy(TempCommand,temp);

		sprintf(ZeroString, "%d", SelectZrCrOn);
		
		strcat(TempCommand,ZeroString);


		strcpy(writeOut,TempCommand);
	
		pvPut(writeOut);
	
		temp=commands[2];
		strcpy(commandOut,temp);
	
		pvPut(commandOut,SYNC);
	

			}


            } state start


when (efTestAndClear( ZeroCrInFlag )){ 

		     	
			
			if (ZeroCrIn==1)
			{


		AcqNumS=1;
		pvPut(AcqNumS);

		/* SET ZERO CHECK ON */
		SelectZrCkOn=1;
		pvPut(SelectZrCkOn);
		
		temp=commands[8];

		strcpy(TempCommand,temp);
		
		sprintf(ZeroString, "%d", SelectZrCkOn);
		
		strcat(TempCommand,ZeroString);

		strcpy(writeOut,TempCommand);
	
		pvPut(writeOut);

		
		temp=commands[10];
		strcpy(writeOut,temp);
		pvPut(writeOut);
		temp=commands[11];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);

		/* SET ZERO CORRECT  ON */

		SelectZrCrOn=1;
		pvPut(SelectZrCrOn);
		
		temp=commands[9];

		strcpy(TempCommand,temp);
		
		sprintf(ZeroString, "%d", SelectZrCrOn);
		
		strcat(TempCommand,ZeroString);

		strcpy(writeOut,TempCommand);
	
		pvPut(writeOut);

		/* SET ZERO CHECK OFF*/
		SelectZrCkOn=0;
		pvPut(SelectZrCkOn);
		
		temp=commands[8];

		strcpy(TempCommand,temp);
		
		sprintf(ZeroString, "%d", SelectZrCkOn);
		
		strcat(TempCommand,ZeroString);

		strcpy(writeOut,TempCommand);
	
		pvPut(writeOut);


		temp=commands[2];
		strcpy(commandOut,temp);
	
		pvPut(commandOut,SYNC);


		
	



			}


            } state start


when (efTestAndClear( RstFlag )){ 
		

		if (Rst==1)	
	     				{

		MonitorCur=0;
		pvPut(MonitorCur);

		/* Put SCAN in PASSIVE mode */

		temp=commands[13];
		strcpy(ScanSerial,temp);
		pvPut(ScanSerial);


		AcqNumS=1;
		pvPut(AcqNumS);

		SelectZrCkOn=1;
		pvPut(SelectZrCkOn);
		

		temp=commands[12];
		strcpy(writeOut,temp);
		
		pvPut(writeOut);

		
		temp=commands[1];
		strcpy(writeOut,temp);
		pvPut(writeOut);
		

		temp=commands[2];
		strcpy(commandOut,temp);
		pvPut(commandOut,SYNC);



			}


            } state start
/* This is a block for monitoring the current 1 second, 1 reading */

when (efTestAndClear( MonitorCurFlag )){ 

		
		if (MonitorCur==1)	
	     				{
		temp=commands[3];

		strcpy(TempCommand,temp);

		AcqNumS=1;
		pvPut(AcqNumS);
		
		strcat(TempCommand,"1");

		strcpy(writeOut,TempCommand);
		pvPut(writeOut);

		temp=commands[14];

		strcpy(ScanSerial,temp);
		pvPut(ScanSerial);

		temp=commands[2];

		strcpy(commandOut,temp);
		pvPut(commandOut);
		

			}


            } state start



/* Stop Scanning by seting the SCAN field to passive, displays last reading */

when (efTestAndClear( StopMonitorCurFlag )){ 

	     				{

		
		temp=commands[13];
	
		strcpy(ScanSerial,temp);

		pvPut(ScanSerial);


		temp=commands[2];

		strcpy(commandOut,temp);

		pvPut(commandOut,SYNC);



			}


            } state start


when (efTestAndClear( currentInpFlag )){

			{

	
		GetCopy(currentInp, buffer);
/*		printf("This is a Buffer :%s\n", buffer);		*/
		 
							
		current=GetCurrent( buffer,StatsCurrent, AcqNumS-1);

/*		printf("This is a current :%e\n", current);	*/


		AcqTotal=current;


		pvPut(AcqTotal); 


	

		AcqMin=StatsCurrent[0];	

		pvPut(AcqMin);
	
		AcqMax=StatsCurrent[1];

		pvPut(AcqMax);		


		if (Acquire==1)
		{
		Acquire=0;
		pvPut(Acquire);	
		}


		 pvGet(Busy);	
		if (Busy==1)
		
		{  
		
		Busy=0;
		pvPut(Busy);	

/*	printf("Buffer at the end %s \n", buffer);	*/	

		
		}
		
	
	

			}


            } state start






when (delay(5.0)&&(Busy<1)){ 

	     		{
/*	printf("Delay %f ,\n", 5.0+AcqNumS);  needs attention does not work numS>5    */

		{
		MonitorCur=1;
		pvPut(MonitorCur);

		}


			}


            } state start

/*           */




} 




}/*End of ss program*/


/*function definitions in C*/
/* This function copies a string from the StrSource from index St(art) to index Fin(ish) */ 

%{
void GetString( char *StrSource, char *StrDest, int St, int Fin)
{
int i=0;
int Ln=0;

/* char *StrDest; error if initialized to a string*/

Ln=strlen(StrSource);




if (Fin>=Ln) Fin=Ln;

if (Fin==St) {printf("Fin=%d St=%d Nothing to copy\n",Fin,St);return;}


    
	strcpy(StrDest,StrSource);
	while (i<(Fin-St)){
	StrDest[i]=StrSource[i+St];
	i=i+1;}
	StrDest[Fin-St]='\0';
return;
}

/* This function copies a source buffer to a buffer string containing AcqSamples number of inputs */ 

void GetCopy(char StrSource[], char *chararray)
{


if (strlen(StrSource)>=MAX_LEN) {printf("Unexpected length of the input string\n"); return;} 


strcpy(chararray,StrSource);

return;
}

/* This function sums the currents in the buffer  */
 
float GetCurrent( char *StrSource,float StatsDest[], int Num)
{
int i=0; 
int  length=0;
float temp=0;
float current=0;
char StrDest[MAX_LEN];

char *ptr="             ";		
char tempPtr[MAX_LEN];
float currentmin=0;
float currentmax=0;



if (strlen(StrSource)!= (1+Num)*14-1){ printf("Unexpected data length   %d \n", strlen(StrSource));return 0;}


current=atof(StrSource);
currentmax=current;
currentmin=current;

strcpy(tempPtr,StrSource);


for (i=0; i<Num; i++)
{

	
	ptr=strchr(tempPtr, ',');



	GetString(ptr,StrDest,1,14);
	


	temp=atof(StrDest);


	current=current+temp;

	if (temp<currentmin) currentmin=temp;
	if (temp>currentmax) currentmax=temp;


/*	printf("Max current is %1.3e ; Min current is %1.3e\n", currentmax, currentmin); */
/*	printf("total current is %e\n", current);  */
	
	length=strlen(ptr);
	GetString(ptr,tempPtr,1,length);


	
}
	StatsDest[0]=currentmin;
	StatsDest[1]=currentmax; 
return (current);
}


}%	



		
