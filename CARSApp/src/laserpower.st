program laserPower("P=14IDB:")
/*
* Robert Henning 2/2010
* Calculate mj/mm2 for each filter position and put on plot.
* Remove some of the delays to speed it up.
* Flag if laser shutter is closed and/or if power is too low.
* Be able to generate a table of values.
* Test with large head. Add switch?
* Save and Restore. Min and Max.
* Remove "set to Max"? Or set desired to max.
*
*/

%% #include <string.h>
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
assign debugLevel  to "{P}LPDebugLevel.VAL";
monitor debugLevel;

int SCAN;
assign SCAN to "{P}Laser_Scan.VAL";
monitor SCAN; 
evflag SCANflag; sync SCAN SCANflag;

int STOP;
assign STOP to "{P}Laser_Stop.VAL";
monitor STOP; 
evflag STOPflag; sync STOP STOPflag;

int SCANNING;
assign SCANNING to "{P}Laser_Scanning.VAL";

int TIME;
assign TIME to "{P}Laser_Time.PROC";

double LP_desired;
assign LP_desired to "{P}Laser_desired.VAL";
monitor LP_desired;
evflag LP_desiredflag; sync LP_desired LP_desiredflag;

double LP_calc;
assign LP_calc to "{P}Laser_calc.VAL";

double LP_avg;
assign LP_avg to "{P}Laser_avg.VAL";
monitor LP_avg;

double LP_size;
assign LP_size to "{P}Laser_size.C";
monitor LP_size;
evflag LP_sizeflag; sync LP_size LP_sizeflag;

double LP_max;
assign LP_max to "{P}Laser_max.VAL";

double LP_min;
assign LP_min to "{P}Laser_min.VAL";

//int LP_num;
//assign LP_num to "{P}Laser_Num.VAL";

double LP_VNstart;
assign LP_VNstart to "{P}Laser_VNstart.VAL";
monitor LP_VNstart;

double LP_VNend;
assign LP_VNend to "{P}Laser_VNend.VAL";
monitor LP_VNend;

double LP_VNcalc;
assign LP_VNcalc to "{P}Laser_VNcalc.VAL";

//monitor LP_desired;
//evflag LP_desiredflag; sync LP_desired LP_desiredflag;

// IDB VN Filter
double VNFilter_DRV;
assign VNFilter_DRV to "{P}m32.VAL";

double VNFilter_DMOV;
assign VNFilter_DMOV to "{P}m32.DMOV";
monitor VNFilter_DMOV;

// Sigma meter PV's
double   sigmaMeterAve;              
assign sigmaMeterAve   to "{P}sigmaMeterAve.VAL";
monitor sigmaMeterAve;

double   sigmaMeterHz;              
assign sigmaMeterHz   to "{P}sigmaMeterHz.VAL";
monitor sigmaMeterHz;

double   sigmaMeterPri;              
assign sigmaMeterPri   to "{P}sigmaMeterPri.VAL";
monitor sigmaMeterPri;

string  sigmaMeterOVR;
assign sigmaMeterOVR    to "{P}sigmaMeterOvr.VAL";
monitor sigmaMeterOVR;

string  sigmaMeterScanUpdate;
assign sigmaMeterScanUpdate    to "{P}sigmaMeterScanUpdate.SCAN";

string statOnOff;
assign statOnOff to "{P}sigmaMeterStatOnOff";
monitor statOnOff;

double   sigmaMeterConfRang;              
assign sigmaMeterConfRang   to "{P}sigmaMeterConfRang.VAL";
monitor sigmaMeterConfRang;

double   sigmaMeterSetRang;              
assign sigmaMeterSetRang   to "{P}sigmaMeterSetRang.VAL";
monitor sigmaMeterSetRang;

char statModeVal[3];
//string Rang; string Rang2;
int i; int j; int k; int l;

double vals[3][31];
assign vals to {"{P}Laser_VN_pos.VAL","{P}Laser_VN_en.VAL","{P}Laser_VN_pow"};

int NELM_pos; assign NELM_pos to "{P}Laser_VN_pos_sub.NELM";
int NELM_en; assign NELM_en to "{P}Laser_VN_en_sub.NELM";
int NELM_pow; assign NELM_pow to "{P}Laser_VN_pow_sub.NELM";

double temp_vals; double sigmaMeterPri_temp;
double LP;
int END;


ss laserPower{
	state init {
		when() {
			efClear(SCANflag);
			efClear(LP_desiredflag);
			efClear(LP_sizeflag);
			LP_VNcalc=0.0; pvPut(LP_VNcalc);
		} state scan 
	} 

	state scan {
        	when(efTestAndClear(SCANflag)) {
			SCANNING=1;pvPut(SCANNING);
			END=LP_VNend/10+1;
			for(k=0;k<=31;k++) {
				vals[0][k]=k*10;
				vals[1][k]=0.0;
			}
			strcpy(statOnOff,"0");pvPut(statOnOff);
			strcpy(sigmaMeterScanUpdate,".1 second"); pvPut(sigmaMeterScanUpdate);
			sigmaMeterSetRang=3; pvPut(sigmaMeterSetRang);
			VNFilter_DRV=0; pvPut(VNFilter_DRV);epicsThreadSleep(0.1);
			while (VNFilter_DMOV==0) {
				Debug(2,"Moving\n");
				epicsThreadSleep(0.5);
			}
			Debug(2,"Pri =%8f\n",sigmaMeterPri);
			while((strcmp(sigmaMeterOVR,"OVR"))==0) {
				Debug(2,"%s\n",sigmaMeterOVR);
				sigmaMeterSetRang=sigmaMeterSetRang-1; pvPut(sigmaMeterSetRang);
				pvPut(sigmaMeterConfRang,SYNC);
				epicsThreadSleep(5.0);
				Debug(2,"%s\n",sigmaMeterOVR);
			}
			while((strcmp(sigmaMeterOVR,"No triggers"))==0) {
				Debug(2,"%s\n",sigmaMeterOVR);
				sigmaMeterSetRang=sigmaMeterSetRang+1; pvPut(sigmaMeterSetRang);
				epicsThreadSleep(10.0);
				Debug(2,"%s\n",sigmaMeterOVR);
			}
			if(sigmaMeterPri<1e-7) Debug(2,"No signal\n");

			for(i=0;i<END;i++) {
				if(STOP==1) 
				{
					Debug(2,"STOP\n");
					STOP=0;pvPut(STOP);
					break;
				}
				else
				{
					VNFilter_DRV=i*10.0;pvPut(VNFilter_DRV);epicsThreadSleep(0.5);
					while (VNFilter_DMOV==0) {
						Debug(2,"Moving\n");
						epicsThreadSleep(0.5);
					}
					vals[0][i]=VNFilter_DRV;
					if((sigmaMeterPri<3e-2)&&(sigmaMeterPri>2.5e-3)) {
						sigmaMeterSetRang=0;pvPut(sigmaMeterSetRang);epicsThreadSleep(0.5);
					}
					if((sigmaMeterPri<2.5e-3)&&(sigmaMeterPri>2.5e-4)) {
						sigmaMeterSetRang=1;pvPut(sigmaMeterSetRang);epicsThreadSleep(0.5);
					}
					if((sigmaMeterPri<2.5e-4)&&(sigmaMeterPri>2.5e-5)) {
						sigmaMeterSetRang=2;pvPut(sigmaMeterSetRang);epicsThreadSleep(0.5);
					}
					if((sigmaMeterPri<2.5e-5)&&(sigmaMeterPri>2.5e-6)) {
						sigmaMeterSetRang=3;pvPut(sigmaMeterSetRang);epicsThreadSleep(0.5);
					}
					if((sigmaMeterPri<2.5e-6)&&(sigmaMeterPri>2.5e-7)) {
						sigmaMeterSetRang=4;pvPut(sigmaMeterSetRang);epicsThreadSleep(0.5);
					}
					temp_vals=0;
					epicsThreadSleep(0.5);
					for(j=0;j<LP_avg;j++) {
						epicsThreadSleep(0.1);					
						sigmaMeterPri_temp=sigmaMeterPri;
						if(sigmaMeterPri_temp==0.0) {
							sigmaMeterSetRang=sigmaMeterSetRang-1;
							pvPut(sigmaMeterSetRang);
							epicsThreadSleep(5.0);
							j--;
							Debug(2,"Changed Meter range\n");
						}
						else 
						{
							temp_vals+=sigmaMeterPri_temp;
						}
					}
//					LP_num=i; pvPut(LP_num);
					vals[1][i]=(temp_vals/LP_avg)*1000000;
					vals[2][i]=vals[1][i]/(LP_size*1000);
					pvPut(vals[0]); pvPut(vals[1]); pvPut(vals[2]);
					NELM_pos=END;pvPut(NELM_pos);
					NELM_en=END;pvPut(NELM_en);
					NELM_pow=END;pvPut(NELM_pow);
					Debug(2,"%f %f %f\n",vals[0][i],vals[1][i],vals[2][i]);
				}
			}
			LP_max=vals[1][0]/(LP_size*1000);pvPut(LP_max);
			LP_min=vals[1][END-1]/(LP_size*1000);pvPut(LP_min);
			SCAN=0;
			pvPut(SCAN);
			efClear(SCANflag);
			pvPut(vals[0]); pvPut(vals[1]);
			TIME=0;pvPut(TIME);
			SCANNING=0;pvPut(SCANNING);
			Debug(2,"Done with Scan\n");
		} state scan

		when(efTest(LP_desiredflag)) {
			LP=LP_desired*LP_size*1000.0;
			Debug(2,"LP = %f, Beam area = %f\n",LP,LP_size);
			for(l=0;l<END;l++) {
				if((LP<=vals[1][l]) && (LP>=vals[1][l+1])) {
					LP_VNcalc=vals[0][l]+(LP-vals[1][l])*((vals[0][l+1]-vals[0][l])/(vals[1][l+1]-vals[1][l]));
					pvPut(LP_VNcalc);
					if (efTest(LP_desiredflag))
						{
						VNFilter_DRV=LP_VNcalc; pvPut(VNFilter_DRV);
						LP_calc=LP_desired*LP_size*1000;pvPut(LP_calc);
						}
					LP_max=vals[1][0]/(LP_size*1000);pvPut(LP_max);
					LP_min=vals[1][END-1]/(LP_size*1000);pvPut(LP_min);
					Debug(2,"LP_max, LP_min, VNcalc = %f %f %f\n",LP_max,LP_min,LP_VNcalc);
				}
			}
			Debug(2,"Done with desired calc\n");
			efClear(LP_desiredflag);
		} state scan

		when(efTestAndClear(LP_sizeflag)) {
			LP_max=vals[1][0]/(LP_size*1000);pvPut(LP_max);
			LP_min=vals[1][END-1]/(LP_size*1000);pvPut(LP_min);
		} state scan
	}

} /* End ss laserPower */

