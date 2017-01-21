program MSShutterMono("P=14LAB:, M1=phi, D=DAC1_1")

/* This program is designed to open and close shutter on manual request and for the time exposure */
/* This program is desined to do a snapshot : rotate phi axis with speed, defined by the */
/* oscillation width, and the exposure time and close and open shutter for the snapshot */
/* it monitors Phi motor record parameters, and use DAC by sending TTL signal 0V close 5V open the MS shutter */
/*
*Macro parameters:
* P=string	Prefix for PV names P=14LAB
* M1=string	Prefix for goniostat axis Phi
* D=string	Prefix for MS Shutter open and close
*/

/* include headers */

%% #include <string.h>
%% #include <stdio.h>
%% #include <stdlib.h>
%% #include <ctype.h>
%% #include <epicsTime.h>
%% #include <time.h>
%% #include <math.h>

/* define parameters needed  */



#define EXP_SHUTTER_OPEN 5
#define EXP_SHUTTER_CLOSE 0
#define EXP_BUSY 1
#define EXP_DONE 0
#define GON_STOP 1
#define YES 1
#define NO 0
#define GON_VEL_MIN 0.001




option +r; 
option -a;


/* Goniometer Phi related variables */

double gonioPhi; assign gonioPhi "{P}{M1}.RBV"; monitor gonioPhi;
double gonioPhiDesired; assign gonioPhiDesired "{P}{M1}.VAL"; monitor  gonioPhiDesired;
double gonioPhiDeadband; assign gonioPhiDeadband "{P}{M1}.RDBD"; monitor gonioPhiDeadband;
short  gonioPhiStop; assign gonioPhiStop "{P}{M1}.STOP"; monitor gonioPhiStop;
double  gonioPhiVelocity; assign gonioPhiVelocity "{P}{M1}.VELO";
double  gonioPhiVelocityMin; assign gonioPhiVelocityMin "{P}{M1}.VBAS";
double  gonioPhiVelocityMax; assign gonioPhiVelocityMax "{P}{M1}.VMAX"; 
double  gonioPhiAcceleration; assign gonioPhiAcceleration "{P}{M1}.ACCL";
double  gonioPhiVelocitySave;
double  gonioPhiAccelerationSave;
double  gonioPhiVelocityMinSave;

/* Exposure MS Shutter related variables */

int exposureShutter; assign exposureShutter "{P}{D}.VAL";

/* Operation of Shutter and Data Collection Interface variables */

int ManualExpShutter; assign ManualExpShutter "{P}ExposeMSShutter.VAL"; monitor ManualExpShutter;
evflag ManualExpShutterRequest; sync ManualExpShutter ManualExpShutterRequest;

int AbortOperation; assign AbortOperation "{P}AbortMSShutter.VAL"; monitor AbortOperation; 
evflag AbortOperationRequest; sync AbortOperation AbortOperationRequest;

int OpenShutter; assign OpenShutter "{P}OpenMSShutter.VAL"; monitor OpenShutter;
evflag OpenShutterRequest; sync OpenShutter OpenShutterRequest;

int CloseShutter; assign CloseShutter "{P}CloseMSShutter.VAL"; monitor CloseShutter;
evflag CloseShutterRequest; sync CloseShutter CloseShutterRequest;

int StartSnapShot; assign StartSnapShot "{P}StartSnapShot.VAL"; monitor StartSnapShot;
evflag StartSnapShotRequest; sync StartSnapShot StartSnapShotRequest;

int ShutterBusy; assign ShutterBusy "{P}MSShutterBusy.VAL"; monitor ShutterBusy;

/* Error management */

string ErrorMessage; assign ErrorMessage "{P}Error_String.VAL";




/* double StartOscillationAngle; 	assign StartOscillationAngle "{P}StartAngle.VAL"; */
double OscillationWidth;      	assign OscillationWidth "{P}OscWidth.VAL";
double OscillationExposureTime;	assign OscillationExposureTime "{P}ExpTime.VAL";
double ManualExposureTime; 	assign ManualExposureTime "{P}ExpTimeMan.VAL";

/* program variables */

double AccelerationPhiAngle;
double RampUpPhiAngle;
double RampDownPhiAngle;
double OscillationPhiVelocity;
double StartOscillationAngle;



double DelayTime;





ss MSShutterMono{

	/*initialization procedures and values*/

	state init{

	    when(){


			}state ManualExposure

		/*end initialization*/
			}


	state ManualExposure {
	
	/*report if expose button is pressed. collect for a given exposure time*/


		when (efTestAndClear( ManualExpShutterRequest)&& ManualExpShutter){ 


			strcpy(ErrorMessage," ");        
			pvPut(ErrorMessage); 
			

	
	
			exposureShutter=EXP_SHUTTER_OPEN;
			pvPut(exposureShutter);
			ShutterBusy=EXP_BUSY;
			pvPut(ShutterBusy);
			pvGet(ManualExposureTime);
			DelayTime=ManualExposureTime;
			
		
						
					
								}state ManualExposure
		/*close the shutter after delay time */

		when (delay(DelayTime)&&(ManualExpShutter)){

			exposureShutter=EXP_SHUTTER_CLOSE;
			pvPut(exposureShutter);
			ShutterBusy=EXP_DONE;
			pvPut(ShutterBusy);
			ManualExpShutter=0;
			pvPut(ManualExpShutter);

	
					}state ManualExposure 
                                        
				}
}


ss ManualOpenOperation{



	state ManualOpenShutter{
		
			when (efTestAndClear(OpenShutterRequest)&&OpenShutter){
			
			strcpy(ErrorMessage," ");        
			pvPut(ErrorMessage); 
			

 
	

		/* when Open is pressed then open the shutter */
			exposureShutter=EXP_SHUTTER_OPEN;
			pvPut(exposureShutter);
			ShutterBusy=EXP_BUSY;
			pvPut(ShutterBusy);
			OpenShutter=0;
			pvPut(OpenShutter);


		
				
		
								}state ManualOpenShutter
				}

}

ss ManualCloseOperation{

	state ManualCloseShutter{
		
			when (efTestAndClear(CloseShutterRequest)&&CloseShutter){  



		/* when Close is pressed then close the shutter */
			exposureShutter=EXP_SHUTTER_CLOSE;
			pvPut(exposureShutter);
			ShutterBusy=EXP_DONE;
			pvPut(ShutterBusy);
			CloseShutter=0;
			pvPut(CloseShutter);



				
		
								}state ManualCloseShutter
				}
}

ss AbortOp{



	state AbortRequested {

			when (efTestAndClear(AbortOperationRequest)&&AbortOperation){ 



		/* when Close is pressed then close the shutter */
			exposureShutter=EXP_SHUTTER_CLOSE;
			pvPut(exposureShutter);
			ShutterBusy=EXP_DONE;
			pvPut(ShutterBusy);



			strcpy(ErrorMessage,"OPERATION ABORTED");        
			pvPut(ErrorMessage); 

			if(StartSnapShot){
			gonioPhiStop=GON_STOP;
			pvPut(gonioPhiStop);
	
					}

			AbortOperation=0;
			pvPut(AbortOperation);


		
			

	
					
			
		
								}state AbortRequested
				}


			
}

ss SnapShotOperation {
	


	state TakeSnapShot{

			when (efTestAndClear(StartSnapShotRequest)&&StartSnapShot){ 

			
			strcpy(ErrorMessage," ");        
			pvPut(ErrorMessage); 
			

			
	



		/* read the assigned values for data collection and for the motion */
			
	

		
			pvGet(gonioPhiVelocity);
			pvGet(gonioPhiVelocityMin);
			pvGet(gonioPhiVelocityMax);
			pvGet(gonioPhiAcceleration);

		

	
			pvGet(OscillationWidth);
			pvGet(OscillationExposureTime);


			pvGet(gonioPhi);
			StartOscillationAngle=gonioPhi;


			
  			gonioPhiVelocitySave=gonioPhiVelocity;
			gonioPhiAccelerationSave=gonioPhiAcceleration;
			gonioPhiVelocityMinSave=gonioPhiVelocityMin;
			
			
								

			/* Oscillation velosity =OscillationWidth/Exposure time */
			OscillationPhiVelocity=OscillationWidth/OscillationExposureTime;
			if (OscillationPhiVelocity>gonioPhiVelocityMax ) 
			{                                                
			strcpy(ErrorMessage,"Max Phi Speed  Exceeded");        
			pvPut(ErrorMessage);                             
			StartSnapShot=0;
			pvPut(StartSnapShot);
			} 


			if (OscillationPhiVelocity<GON_VEL_MIN ) 
			{                                                
			strcpy(ErrorMessage,"Below Min Phi Speed");        
			pvPut(ErrorMessage);                             
			StartSnapShot=0;
			pvPut(StartSnapShot);
			}                                   
			
			if ((OscillationPhiVelocity<= gonioPhiVelocityMin))       
			{ gonioPhiVelocityMin=0.01*OscillationPhiVelocity;}                              
			
		/*      Acceleration angle calculate from x=x0+(v^2-V_0^2)/2a                             */
		/*	AccelerationPhiAngle=pow(OscillationPhiVelocity, 2.0)/(2.0*gonioPhiAcceleration); */

	
			
			AccelerationPhiAngle=(OscillationPhiVelocity+gonioPhiVelocityMin)*gonioPhiAcceleration/2; 

						
								
			if(StartSnapShot)
			{
			RampUpPhiAngle=StartOscillationAngle-AccelerationPhiAngle;

			
   
			gonioPhiDesired=RampUpPhiAngle;
			pvPut(gonioPhiDesired, ASYNC);}
			
			
				}state CheckForRampUpPhiAngleToComplete
					}



				
	state CheckForRampUpPhiAngleToComplete {
			
			when( StartSnapShot<1){
				
				}state RecoverSavedValues


			
			when( gonioPhiStop){
 

				}state RecoverSavedValues

			
			when(StartSnapShot&&pvPutComplete(gonioPhiDesired)){
			
				
			
			gonioPhiVelocity=OscillationPhiVelocity;
			
			pvPut(gonioPhiVelocityMin);

			pvPut(gonioPhiVelocity,ASYNC);

						
	
						}state MoveToRampDownPhiAngle	
						
						}				
											




	state  MoveToRampDownPhiAngle{	

			when( StartSnapShot<1){
			}state RecoverSavedValues




				
			when( gonioPhiStop){


				}state RecoverSavedValues
			

	
			when(StartSnapShot&& pvPutComplete( gonioPhiVelocity )){


			RampDownPhiAngle=StartOscillationAngle+OscillationWidth+ AccelerationPhiAngle;
			gonioPhiDesired=RampDownPhiAngle;
			pvPut(gonioPhiDesired, ASYNC);	
		
				
		
						}state WaitForShutterToOpen		    
						}								



	state WaitForShutterToOpen{

			when( StartSnapShot<1){
			}state RecoverSavedValues



				
			when( gonioPhiStop){
				}state RecoverSavedValues
											

			when(StartSnapShot&&(gonioPhi>=(StartOscillationAngle-gonioPhiDeadband))){  
				


			exposureShutter=EXP_SHUTTER_OPEN;
			pvPut(exposureShutter);
			ShutterBusy=EXP_BUSY; 
			pvPut(ShutterBusy);  

		
						}state WaitForShutterToClose		
						}					




	state  WaitForShutterToClose{ 

				when( StartSnapShot<1){
				}state RecoverSavedValues




				
			when( gonioPhiStop){
				}state RecoverSavedValues


		
			when (StartSnapShot&&(gonioPhi>=(StartOscillationAngle+OscillationWidth-gonioPhiDeadband))){  


			
			exposureShutter=EXP_SHUTTER_CLOSE;
			pvPut(exposureShutter);
			ShutterBusy=EXP_DONE;
			pvPut(ShutterBusy);
			
		
						}state WaitToReachRampDownAngle
						}




	state WaitToReachRampDownAngle{

			when( StartSnapShot<1){
			}state RecoverSavedValues



				
			when( gonioPhiStop){
				}state RecoverSavedValues



			
			when(StartSnapShot&&(pvPutComplete(gonioPhiDesired))){  
			 
										
						}state RecoverSavedValues 
					}




	state RecoverSavedValues{

			when(){

			if (StartSnapShot||gonioPhiStop){

			gonioPhiVelocity=gonioPhiVelocitySave;
			pvPut(gonioPhiVelocity, SYNC);

			gonioPhiAcceleration=gonioPhiAccelerationSave;
			pvPut(gonioPhiAcceleration, SYNC);

			gonioPhiVelocityMin=gonioPhiVelocityMinSave;
			pvPut(gonioPhiVelocityMin);
	
			StartSnapShot=0;
			pvPut(StartSnapShot);
			
			if (gonioPhiStop){
			
			gonioPhiStop=0;
			pvPut(gonioPhiStop);
				}
						

	
				}
			
				
				} state TakeSnapShot
				}

			
}
	





			


