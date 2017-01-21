/* -*-c-*- */
program lxd("P=14IDB:,F=fpga")

/*  
* This sequencer program reads in a desired laser to x-ray delay (lxd), calculates
* the proper fpga valus and writes those values to the fpga registers. 
* This only works for the ps laser.
*
* Robert Henning Dec 2010
* 
*/

%% #include <math.h>
%% #include <string.h>
%% #include "epicsTime.h"

%{
  double Round_Up(double value, double inc);
  double Round(double value);
}%

//%% static int set_reg(char *var, int value);

option +r;
option -a;

int Debug; assign Debug to "{P}lxd_debug"; monitor Debug;
int Busy; assign Busy to "{P}lxd_busy";

double LXD; assign LXD to "{P}lxd"; monitor LXD; evflag LXDflag; sync LXD LXDflag;

double LXD_OFFSET; assign LXD_OFFSET to "{P}{F}_OFFSET:lxd";monitor LXD_OFFSET;
double LXD_XD_OFFSET; assign LXD_XD_OFFSET to "{P}{F}_OFFSET:lxd_xd";monitor LXD_XD_OFFSET;
double PSDC_PSD1_OFFSET; assign PSDC_PSD1_OFFSET to "{P}{F}_OFFSET:psdc_psd1";monitor PSDC_PSD1_OFFSET;
double XOSCT_OFFSET; assign XOSCT_OFFSET to "{P}{F}_OFFSET:xosct";monitor XOSCT_OFFSET;
double LXD_XOSCT_OFFSET; assign LXD_XOSCT_OFFSET to "{P}{F}_OFFSET:lxd_xosct";monitor LXD_XOSCT_OFFSET;
int ClearSweeps; assign ClearSweeps to "{P}waveSurfer:clearSweeps.PROC";

double PSD1; assign PSD1 to "{P}{F}_DRV:psd1";
double PSD2; assign PSD2 to "{P}{F}_DRV:psd2";
double PSD3; assign PSD3 to "{P}{F}_DRV:psd3";
double MSD2; assign MSD2 to "{P}{F}_DRV:msd2";
double XOSCT2; assign XOSCT2 to "{P}{F}_DRV:xosct2";
double XOSCT1; assign XOSCT1 to "{P}{F}_DRV:xosct1";
double LOSCT2; assign LOSCT2 to "{P}{F}_DRV:losct2";
double LOSCT1; assign LOSCT1 to "{P}{F}_DRV:losct1";

/* Bunch Clock Freq (Hz) */
double bcf;
double P0f;
double hscf;
double hlcf;

double LXD_dial;
double XD;
double LD;
double PSD3_dial;
double PSDC_dial;
double PSD1_dial;
double PSD2_dial;
double MSD2_dial;
double XOSCT_value;
double XOSCT_dial;
double XOSCT2_dial;
double XOSCT1_dial;
double LOSCT_value;
double LOSCT_dial;
double LOSCT2_dial;
double LOSCT1_dial;

float sleep;

ss lxd {
  state init {
    when() {
      bcf = 351933980.0;
      P0f = bcf/1296;
      hscf = P0f/275;
      hlcf = hscf/12;
      sleep=0.0;
      ClearSweeps = 1;

      //LXD_OFFSET=0.017190319110;

      efClear(LXDflag);
   } state set
      }

  state set {

    when(efTestAndClear(LXDflag)) {
      if (Debug == 1) printf("LXD=%.12f\n",LXD);
      if (Debug == 1) printf("LXD_OFFSET=%.12f\n",LXD_OFFSET);
      if (Debug == 1) printf("LXD_XD_OFFSET=%.12f\n",LXD_XD_OFFSET);

      pvPut(ClearSweeps);pvFlush();

      LXD_dial = LXD-LXD_OFFSET;
      if (Debug == 1) printf("LXD_dial=%.12f\n",LXD_dial);
      
      XD = Round_Up((LXD_dial-LXD_XD_OFFSET),1.0/hlcf)+LXD_XD_OFFSET;
      while (XD < 0) XD += 1/hlcf;
      if (Debug == 1) printf("XD=%.12f\n",XD);

      LD = XD - LXD_dial;
      if (Debug == 1) printf("LD=%.12f\n",LD);

      %% pVar->PSD3_dial = pVar->LD - fmod(pVar->LD,(1/pVar->hscf));
      if (Debug == 1) printf("PSD3_dial=%.12f\n",PSD3_dial);

      PSD3 = Round(PSD3_dial * hscf);
      if (Debug == 1 || Debug == 2) printf("PSD3=%.12f\n",PSD3);
      pvPut(PSD3);
      pvFlush();
      epicsThreadSleep(sleep);

      PSDC_dial = LD - PSD3_dial;
      if (Debug == 1) printf("PSDC_dial=%.12f\n",PSDC_dial);

      %% pVar->PSD1_dial = fmod((pVar->PSDC_dial+pVar->PSDC_PSD1_OFFSET),5.0/pVar->bcf);
      if (Debug == 1) printf("PSD1_dial=%.12f\n",PSD1_dial);

      PSD1 = Round(PSD1_dial/0.000000000010048);
      if (Debug == 1 || Debug == 2) printf("PSD1=%.12f\n",PSD1);
      pvPut(PSD1);
      pvFlush();
      epicsThreadSleep(sleep);

      PSD2_dial = PSDC_dial;
      if (Debug == 1) printf("PSD2_dial=%.12f\n",PSD2_dial);

      PSD2 = Round(PSD2_dial*bcf);
      if (Debug == 1 || Debug == 2) printf("PSD2=%.12f\n",PSD2);
      pvPut(PSD2);
      pvFlush();
      epicsThreadSleep(sleep);

      MSD2_dial = XD;
      if (Debug == 1) printf("MSD2_dial=%.12f\n",MSD2_dial);

      MSD2 = Round(MSD2_dial*hscf);
      if (Debug == 1 || Debug == 2) printf("MSD2=%.12f\n",MSD2);
      pvPut(MSD2);
      pvFlush();
      epicsThreadSleep(sleep);

      XOSCT_value = XD - LXD_XD_OFFSET;
      if (Debug == 1) printf("XOSCT_value=%.12f\n",XOSCT_value);

      XOSCT_dial = XOSCT_value - XOSCT_OFFSET;
      if (Debug == 1) printf("XOSCT_dial=%.12f\n",XOSCT_dial);

      %% pVar->XOSCT2_dial = pVar->XOSCT_dial - fmod(pVar->XOSCT_dial,1.0/pVar->hscf);
      if (Debug == 1) printf("XOSCT2_dial=%.12f\n",XOSCT2_dial);

      XOSCT2 = Round(XOSCT2_dial * hscf);
      if (Debug == 1 || Debug == 2) printf("XOSCT2=%.12f\n",XOSCT2);
      pvPut(XOSCT2);
      pvFlush();
      epicsThreadSleep(sleep);

      XOSCT1_dial = XOSCT_dial - XOSCT2_dial;
      if (Debug == 1) printf("XOSCT1_dial=%.12f\n",XOSCT1_dial);

      XOSCT1 = Round(XOSCT1_dial * bcf);
      if (Debug == 1 || Debug == 2) printf("XOSCT1=%.12f\n",XOSCT1);
      pvPut(XOSCT1);
      pvFlush();
      epicsThreadSleep(sleep);

      LOSCT_value = LD + LXD_XOSCT_OFFSET;
      if (Debug == 1) printf("LOSCT_value=%.12f\n",LOSCT_value);

      LOSCT_dial = LOSCT_value;
      if (Debug == 1) printf("LOSCT_dial=%.12f\n",LOSCT_dial);

      %% pVar->LOSCT2_dial = pVar->LOSCT_dial - fmod(pVar->LOSCT_dial,1.0/pVar->hscf);
      if (Debug == 1) printf("LOSCT2_dial=%.12f\n",LOSCT2_dial);

      LOSCT2 = Round(LOSCT2_dial * hscf);
      if (Debug == 1 || Debug == 2) printf("LOSCT2=%.12f\n",LOSCT2);
      pvPut(LOSCT2);
      pvFlush();
      epicsThreadSleep(sleep);

      LOSCT1_dial = LOSCT_dial - LOSCT2_dial;
      if (Debug == 1) printf("LOSCT1_dial=%.12f\n",LOSCT1_dial);

      LOSCT1 = Round(LOSCT1_dial * bcf);
      if (Debug == 1 || Debug == 2) printf("LOSCT1=%.12f\n",LOSCT1);
      pvPut(LOSCT1);
      pvFlush();
      epicsThreadSleep(sleep);

      // Wait for the fpga to process before allowing the busy record to be set to done.
      // Should calc lxd_rbv instead.
      epicsThreadSleep(1.0);
      Busy=0;
      pvPut(Busy); pvFlush();

    } state set
	}
}

// Do this when it gets merged into fpga.st
//ss lxd_rbv {
//  state rbv {
//    when (delay(1.0)) {
      

%{
// This function rounds a double to a specified increment.
double Round_Up(double value, double inc)
{
  return (ceil(value/inc)*inc);
}
double Round(double value)
{
  return (floor(value+0.5));
}
}%
