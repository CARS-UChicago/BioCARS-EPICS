/* -*-c-*- */
program fpga("P=14IDB:,S=serial18,F=fpga")

/*  
* This sequencer program communicates with the fpga in 14IDB
* Robert Henning May 2009
* 
* Cleaned up code to remove read error. 110105 RH
* Merge lxd into fpga code. 110105 RH
* Added busy records for lxd and pulses. 110106 RH
* Added functions fpgaWing and fpgaWdouble. 110106 RH
* Noticed that psmode was change to pspump in the fpga. PV name left unchanged. 110106 RH
*
* To Do List:
* This only works with the ps laser. Get it to work with the ns laser.
* 39 character limit is reached when the parameters are updated through MEDM.
*  -Streamdevice might fix this but that is a lot of work.
*
*/

%% #include <math.h>
%% #include <string.h>
%% #include <unistd.h>
%% #include "epicsTime.h"

%{
  double Round_Up(double value, double inc);
  int Round(double value);
  void fpgaWint(SS_ID ssId, struct UserVar *pVar, char *cmd, int value, int scan);
  void fpgaWdouble(SS_ID ssId, struct UserVar *pVar, char *cmd, double value, int scan);
  int fpgaRint(SS_ID ssId, struct UserVar *pVar, char *cmd, int i);
}%

option +r;
option -a;

int Debug; assign Debug to "{P}fpga_debug"; monitor Debug;
int LXD_Busy; assign LXD_Busy to "{P}lxd_busy";
int PULSES_Busy; assign PULSES_Busy to "{P}pulses_busy";

string AOUT; assign AOUT to "{P}{S}.AOUT"; 
string AINP; assign AINP to "{P}{S}.AINP"; monitor AINP;
int TMOD; assign TMOD to "{P}{S}.TMOD"; monitor TMOD;
float SCAN; assign SCAN to "{P}{F}_SCAN.VAL"; monitor SCAN;

evflag doScan;

/* Setup links to scan through current register settings*/
int fpga_line_num[39];  
assign fpga_line_num[0] to "{P}{F}_RBV:ver.VAL";
assign fpga_line_num[1] to "{P}{F}_RBV:clksrc.VAL";
assign fpga_line_num[2] to "{P}{F}_RBV:clkstat.VAL";
assign fpga_line_num[3] to "{P}{F}_RBV:clkrst.VAL";
assign fpga_line_num[4] to "{P}{F}_RBV:p0fd.VAL";
assign fpga_line_num[5] to "{P}{F}_RBV:p0ad.VAL";
assign fpga_line_num[6] to "{P}{F}_RBV:p0d.VAL";
assign fpga_line_num[7] to "{P}{F}_RBV:p0led.VAL";
assign fpga_line_num[8] to "{P}{F}_RBV:lmode.VAL";
assign fpga_line_num[9] to "{P}{F}_RBV:tmode.VAL";
assign fpga_line_num[10] to "{P}{F}_RBV:pulses.VAL";
assign fpga_line_num[11] to "{P}{F}_RBV:nswaitt.VAL";
assign fpga_line_num[12] to "{P}{F}_RBV:pswaitt.VAL";
assign fpga_line_num[13] to "{P}{F}_RBV:xwaitt.VAL";
assign fpga_line_num[14] to "{P}{F}_RBV:pson.VAL";
assign fpga_line_num[15] to "{P}{F}_RBV:psd1.VAL";
assign fpga_line_num[16] to "{P}{F}_RBV:psd2.VAL";
assign fpga_line_num[17] to "{P}{F}_RBV:psd3.VAL";
assign fpga_line_num[18] to "{P}{F}_RBV:losct1.VAL";
assign fpga_line_num[19] to "{P}{F}_RBV:losct2.VAL";
assign fpga_line_num[20] to "{P}{F}_RBV:psmode.VAL";
assign fpga_line_num[21] to "{P}{F}_RBV:nson.VAL";
assign fpga_line_num[22] to "{P}{F}_RBV:nsd1.VAL";
assign fpga_line_num[23] to "{P}{F}_RBV:nsd2.VAL";
assign fpga_line_num[24] to "{P}{F}_RBV:nsd3.VAL";
assign fpga_line_num[25] to "{P}{F}_RBV:hlcnd.VAL";
assign fpga_line_num[26] to "{P}{F}_RBV:hlctd.VAL";
assign fpga_line_num[27] to "{P}{F}_RBV:hlcad.VAL";
assign fpga_line_num[28] to "{P}{F}_RBV:hlcled.VAL";
assign fpga_line_num[29] to "{P}{F}_RBV:hscd.VAL";
assign fpga_line_num[30] to "{P}{F}_RBV:mson.VAL";
assign fpga_line_num[31] to "{P}{F}_RBV:msd1.VAL";
assign fpga_line_num[32] to "{P}{F}_RBV:msd2.VAL";
assign fpga_line_num[33] to "{P}{F}_RBV:xosct1.VAL";
assign fpga_line_num[34] to "{P}{F}_RBV:xosct2.VAL";
assign fpga_line_num[35] to "{P}{F}_RBV:transon.VAL";
assign fpga_line_num[36] to "{P}{F}_RBV:transd.VAL";
assign fpga_line_num[37] to "{P}{F}_RBV:diag1.VAL";
assign fpga_line_num[38] to "{P}{F}_RBV:diag2.VAL";

/* Setup event flags to update FPGA when a register is updated through EPICS*/
int CLKSRC;assign CLKSRC to "{P}{F}_DRV:clksrc.VAL";monitor CLKSRC;evflag CLKSRCflag;sync CLKSRC CLKSRCflag;
int CLKRST;assign CLKRST to "{P}{F}_DRV:clkrst.VAL";monitor CLKRST;evflag CLKRSTflag;sync CLKRST CLKRSTflag;
int P0FD;assign P0FD to "{P}{F}_DRV:p0fd.VAL";monitor P0FD;evflag P0FDflag;sync P0FD P0FDflag;
int P0D;assign P0D to "{P}{F}_DRV:p0d.VAL";monitor P0D;evflag P0Dflag;sync P0D P0Dflag;
int LMODE;assign LMODE to "{P}{F}_DRV:lmode.VAL";monitor LMODE;evflag LMODEflag;sync LMODE LMODEflag;
int TMODE;assign TMODE to "{P}{F}_DRV:tmode.VAL";monitor TMODE;evflag TMODEflag;sync TMODE TMODEflag;
int PULSES;assign PULSES to "{P}{F}_DRV:pulses.VAL";monitor PULSES;evflag PULSESflag;sync PULSES PULSESflag;
int NSWAITT;assign NSWAITT to "{P}{F}_DRV:nswaitt.VAL";monitor NSWAITT;evflag NSWAITTflag;sync NSWAITT NSWAITTflag;
int PSWAITT;assign PSWAITT to "{P}{F}_DRV:pswaitt.VAL";monitor PSWAITT;evflag PSWAITTflag;sync PSWAITT PSWAITTflag;
int XWAITT;assign XWAITT to "{P}{F}_DRV:xwaitt.VAL";monitor XWAITT;evflag XWAITTflag;sync XWAITT XWAITTflag;
int PSON;assign PSON to "{P}{F}_DRV:pson.VAL";monitor PSON;evflag PSONflag;sync PSON PSONflag;
int PSD1;assign PSD1 to "{P}{F}_DRV:psd1.VAL";monitor PSD1;evflag PSD1flag;sync PSD1 PSD1flag;
int PSD2;assign PSD2 to "{P}{F}_DRV:psd2.VAL";monitor PSD2;evflag PSD2flag;sync PSD2 PSD2flag;
int PSD3;assign PSD3 to "{P}{F}_DRV:psd3.VAL";monitor PSD3;evflag PSD3flag;sync PSD3 PSD3flag;
int LOSCT1;assign LOSCT1 to "{P}{F}_DRV:losct1.VAL";monitor LOSCT1;evflag LOSCT1flag;sync LOSCT1 LOSCT1flag;
int LOSCT2;assign LOSCT2 to "{P}{F}_DRV:losct2.VAL";monitor LOSCT2;evflag LOSCT2flag;sync LOSCT2 LOSCT2flag;
int PSMODE;assign PSMODE to "{P}{F}_DRV:psmode.VAL";monitor PSMODE;evflag PSMODEflag;sync PSMODE PSMODEflag;
int NSON;assign NSON to "{P}{F}_DRV:nson.VAL";monitor NSON;evflag NSONflag;sync NSON NSONflag;
int NSD1;assign NSD1 to "{P}{F}_DRV:nsd1.VAL";monitor NSD1;evflag NSD1flag;sync NSD1 NSD1flag;
int NSD2;assign NSD2 to "{P}{F}_DRV:nsd2.VAL";monitor NSD2;evflag NSD2flag;sync NSD2 NSD2flag;
int NSD3;assign NSD3 to "{P}{F}_DRV:nsd3.VAL";monitor NSD3;evflag NSD3flag;sync NSD3 NSD3flag;
int HLCND;assign HLCND to "{P}{F}_DRV:hlcnd.VAL";monitor HLCND;evflag HLCNDflag;sync HLCND HLCNDflag;
int HLCTD;assign HLCTD to "{P}{F}_DRV:hlctd.VAL";monitor HLCTD;evflag HLCTDflag;sync HLCTD HLCTDflag;
int HSCD;assign HSCD to "{P}{F}_DRV:hscd.VAL";monitor HSCD;evflag HSCDflag;sync HSCD HSCDflag;
int MSON;assign MSON to "{P}{F}_DRV:mson.VAL";monitor MSON;evflag MSONflag;sync MSON MSONflag;
int MSD1;assign MSD1 to "{P}{F}_DRV:msd1.VAL";monitor MSD1;evflag MSD1flag;sync MSD1 MSD1flag;
int MSD2;assign MSD2 to "{P}{F}_DRV:msd2.VAL";monitor MSD2;evflag MSD2flag;sync MSD2 MSD2flag;
int XOSCT1;assign XOSCT1 to "{P}{F}_DRV:xosct1.VAL";monitor XOSCT1;evflag XOSCT1flag;sync XOSCT1 XOSCT1flag;
int XOSCT2;assign XOSCT2 to "{P}{F}_DRV:xosct2.VAL";monitor XOSCT2;evflag XOSCT2flag;sync XOSCT2 XOSCT2flag;
int TRANSON;assign TRANSON to "{P}{F}_DRV:transon.VAL";monitor TRANSON;evflag TRANSONflag;sync TRANSON TRANSONflag;
int TRANSD;assign TRANSD to "{P}{F}_DRV:transd.VAL";monitor TRANSD;evflag TRANSDflag;sync TRANSD TRANSDflag;
int DIAG1;assign DIAG1 to "{P}{F}_DRV:diag1.VAL";monitor DIAG1;evflag DIAG1flag;sync DIAG1 DIAG1flag;
int DIAG2;assign DIAG2 to "{P}{F}_DRV:diag2.VAL";monitor DIAG2;evflag DIAG2flag;sync DIAG2 DIAG2flag;

/* Setup links to scan through current parameters */
double parameters[17];
assign parameters[0] to "{P}{F}_OFFSET:msd2.VAL";
assign parameters[1] to "{P}{F}_OFFSET:ns_lxd_xd.VAL";
assign parameters[2] to "{P}{F}_OFFSET:ns_lxd.VAL";
assign parameters[3] to "{P}{F}_OFFSET:lxd_xd.VAL";
assign parameters[4] to "{P}{F}_OFFSET:hlcnd.VAL";
assign parameters[5] to "{P}{F}_OFFSET:msd.VAL";
assign parameters[6] to "{P}{F}_OFFSET:xosct.VAL";
assign parameters[7] to "{P}{F}_OFFSET:psdc_psd1.VAL";
assign parameters[8] to "{P}{F}_OFFSET:msd1.VAL";
assign parameters[9] to "{P}{F}_OFFSET:lxd.VAL";
assign parameters[10] to "{P}{F}_OFFSET:hscd.VAL";
assign parameters[11] to "{P}{F}_OFFSET:hlcad.VAL";
assign parameters[12] to "{P}{F}_OFFSET:nsd.VAL";
assign parameters[13] to "{P}{F}_OFFSET:transd.VAL";
assign parameters[14] to "{P}{F}_OFFSET:ns_lxd_xosct.VAL";
assign parameters[15] to "{P}{F}_OFFSET:lxd_xosct.VAL";
assign parameters[16] to "{P}{F}_OFFSET:hlctd.VAL";

/* Setup event flags to update FPGA when a parameter is updated through EPICS
   P in front of event flag name stands for parameter*/
double PMSD2;assign PMSD2 to "{P}{F}_DRV:Pmsd2.VAL";monitor PMSD2;evflag PMSD2flag;sync PMSD2 PMSD2flag;
double PNS_LXD_XD;assign PNS_LXD_XD to "{P}{F}_DRV:Pns_lxd_xd.VAL";monitor PNS_LXD_XD;evflag PNS_LXD_XDflag;sync PNS_LXD_XD PNS_LXD_XDflag;
double PNS_LXD;assign PNS_LXD to "{P}{F}_DRV:Pns_lxd.VAL";monitor PNS_LXD;evflag PNS_LXDflag;sync PNS_LXD PNS_LXDflag;
double PLXD_XD;assign PLXD_XD to "{P}{F}_DRV:Plxd_xd.VAL";monitor PLXD_XD;evflag PLXD_XDflag;sync PLXD_XD PLXD_XDflag;
double PHLCND;assign PHLCND to "{P}{F}_DRV:Phlcnd.VAL";monitor PHLCND;evflag PHLCNDflag;sync PHLCND PHLCNDflag;
double PMSD;assign PMSD to "{P}{F}_DRV:Pmsd.VAL";monitor PMSD;evflag PMSDflag;sync PMSD PMSDflag;
double PXOSCT;assign PXOSCT to "{P}{F}_DRV:Pxosct.VAL";monitor PXOSCT;evflag PXOSCTflag;sync PXOSCT PXOSCTflag;
double PPSDC_PSD1;assign PPSDC_PSD1 to "{P}{F}_DRV:Ppsdc_psd1.VAL";monitor PPSDC_PSD1;evflag PPSDC_PSD1flag;sync PPSDC_PSD1 PPSDC_PSD1flag;
double PMSD1;assign PMSD1 to "{P}{F}_DRV:Pmsd1.VAL";monitor PMSD1;evflag PMSD1flag;sync PMSD1 PMSD1flag;
double PLXD;assign PLXD to "{P}{F}_DRV:Plxd.VAL";monitor PLXD;evflag PLXDflag;sync PLXD PLXDflag;
double PHSCD;assign PHSCD to "{P}{F}_DRV:Phscd.VAL";monitor PHSCD;evflag PHSCDflag;sync PHSCD PHSCDflag;
double PHLCAD;assign PHLCAD to "{P}{F}_DRV:Phlcad.VAL";monitor PHLCAD;evflag PHLCADflag;sync PHLCAD PHLCADflag;
double PNSD;assign PNSD to "{P}{F}_DRV:Pnsd.VAL";monitor PNSD;evflag PNSDflag;sync PNSD PNSDflag;
double PTRANSD;assign PTRANSD to "{P}{F}_DRV:Ptransd.VAL";monitor PTRANSD;evflag PTRANSDflag;sync PTRANSD PTRANSDflag;
double PNS_LXD_XOSCT;assign PNS_LXD_XOSCT to "{P}{F}_DRV:Pns_lxd_xosct.VAL";monitor PNS_LXD_XOSCT;evflag PNS_LXD_XOSCTflag;sync PNS_LXD_XOSCT PNS_LXD_XOSCTflag;
double PLXD_XOSCT;assign PLXD_XOSCT to "{P}{F}_DRV:Plxd_xosct.VAL";monitor PLXD_XOSCT;evflag PLXD_XOSCTflag;sync PLXD_XOSCT PLXD_XOSCTflag;
double PHLCTD;assign PHLCTD to "{P}{F}_DRV:Phlctd.VAL";monitor PHLCTD;evflag PHLCTDflag;sync PHLCTD PHLCTDflag;

/* hscd in seconds 
   S in front of the event flag name stands for seconds*/
double SHSCD; assign SHSCD to "{P}{F}_hscd.VAL";monitor SHSCD; evflag SHSCDflag; sync SHSCD SHSCDflag;
double SHSCD_pos; assign SHSCD_pos to "{P}{F}_hscd_pos.VAL";monitor SHSCD_pos; evflag SHSCD_posflag; sync SHSCD_pos SHSCD_posflag;
double SHSCD_neg; assign SHSCD_neg to "{P}{F}_hscd_neg.VAL";monitor SHSCD_neg; evflag SHSCD_negflag; sync SHSCD_neg SHSCD_negflag;
int SHSCD_step; assign SHSCD_step to "{P}{F}_hscd_step.VAL";monitor SHSCD_step;
int SHSCD_set; assign SHSCD_set to "{P}{F}_hscd_set.VAL";monitor SHSCD_set; evflag SHSCD_setflag; sync SHSCD_set SHSCD_setflag;

/* lxd setup */
double LXD; assign LXD to "{P}lxd"; monitor LXD; evflag LXDflag; sync LXD LXDflag;
// This is redundate but I hope it works. Is the monitor really necessary?
double LXD_OFFSET; assign LXD_OFFSET to "{P}{F}_OFFSET:lxd";monitor LXD_OFFSET;
double LXD_XD_OFFSET; assign LXD_XD_OFFSET to "{P}{F}_OFFSET:lxd_xd";monitor LXD_XD_OFFSET;
double PSDC_PSD1_OFFSET; assign PSDC_PSD1_OFFSET to "{P}{F}_OFFSET:psdc_psd1";monitor PSDC_PSD1_OFFSET;
double XOSCT_OFFSET; assign XOSCT_OFFSET to "{P}{F}_OFFSET:xosct";monitor XOSCT_OFFSET;
double LXD_XOSCT_OFFSET; assign LXD_XOSCT_OFFSET to "{P}{F}_OFFSET:lxd_xosct";monitor LXD_XOSCT_OFFSET;
double LXD_RBV; assign LXD_RBV to "{P}lxd_RBV.VAL";
int ClearSweeps; assign ClearSweeps to "{P}waveSurfer:clearSweeps.PROC";

int CleanVal;
int OldVal[39];
double CleanVal2;

char *Mnemonic[39];
char *Param[18];
int i;int j;
float s;

/* Bunch Clock Freq (Hz) */
double bcf;
double P0f;
double hscf;
double hlcf;

int hscd_counts;
double hscd_temp;
double hscd_value;
double hscd_offset;
int update_hscd;

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

int TMODIndex;
int AOUTIndex;
int AINPIndex;

int LXD_Pause;
double PSDC_temp1;
double PSDC_temp2;
double PSDC_t1;
double PSD_dial;

ss fpga {
  state init {
    when() {
      bcf = 351933980.0;
      P0f = bcf/1296;
      hscf = P0f/275;
      hlcf = hscf/12;
      sleep=0.0;
      ClearSweeps = 1;

      Mnemonic[0]="ver";
      Mnemonic[1]="clksrc";
      Mnemonic[2]="clkstat";
      Mnemonic[3]="clkrst";
      Mnemonic[4]="p0fd";
      Mnemonic[5]="p0ad";
      Mnemonic[6]="p0d";
      Mnemonic[7]="p0led";
      Mnemonic[8]="lmode";
      Mnemonic[9]="tmode";
      Mnemonic[10]="pulses";
      Mnemonic[11]="nswaitt";
      Mnemonic[12]="pswaitt";
      Mnemonic[13]="xwaitt";
      Mnemonic[14]="pson";
      Mnemonic[15]="psd1";
      Mnemonic[16]="psd2";
      Mnemonic[17]="psd3";
      Mnemonic[18]="losct1";
      Mnemonic[19]="losct2";
      Mnemonic[20]="pspump";
      Mnemonic[21]="nson";
      Mnemonic[22]="nsd1";
      Mnemonic[23]="nsd2";
      Mnemonic[24]="nsd3";
      Mnemonic[25]="hlcnd";
      Mnemonic[26]="hlctd";
      Mnemonic[27]="hlcad";
      Mnemonic[28]="hlcled";
      Mnemonic[29]="hscd";
      Mnemonic[30]="mson";
      Mnemonic[31]="msd1";
      Mnemonic[32]="msd2";
      Mnemonic[33]="xosct1";
      Mnemonic[34]="xosct2";
      Mnemonic[35]="transon";
      Mnemonic[36]="transd";
      Mnemonic[37]="diag1";
      Mnemonic[38]="diag2";


      Param[0]="msd2.offset";
      Param[1]="ns_lxd.xd_offset";
      Param[2]="ns_lxd.offset";
      Param[3]="lxd.xd_offset";
      Param[4]="hlcnd.offset";
      Param[5]="msd.offset";
      Param[6]="xosct.offset";
      Param[7]="psdc.psd1_offset";
      Param[8]="msd1.offset";
      Param[9]="lxd.offset";
      Param[10]="hscd.offset";
      Param[11]="hlcad.offset";
      Param[12]="nsd.offset";
      Param[13]="transd.offset";
      Param[14]="ns_lxd.xosct_offset";
      Param[15]="lxd.xosct_offset";
      Param[16]="hlctd.offset";

      TMOD = 1;
      pvPut(TMOD);

      efClear(CLKSRCflag); efClear(CLKRSTflag); efClear(P0FDflag); efClear(P0Dflag); efClear(LMODEflag);
      efClear(TMODEflag);  efClear(PULSESflag); efClear(NSWAITTflag); efClear(PSWAITTflag); efClear(XWAITTflag);
      efClear(PSONflag); efClear(PSD1flag); efClear(PSD2flag); efClear(PSD3flag); efClear(LOSCT1flag);
      efClear(LOSCT2flag); efClear(PSMODEflag); efClear(NSONflag); efClear(NSD1flag); efClear(NSD2flag);
      efClear(NSD3flag); efClear(HLCNDflag); efClear(HLCTDflag); efClear(HSCDflag); efClear(MSONflag);
      efClear(MSD1flag); efClear(MSD2flag); efClear(XOSCT1flag); efClear(XOSCT2flag); efClear(TRANSONflag);
      efClear(TRANSDflag); efClear(DIAG1flag); efClear(DIAG2flag);

      efClear(PMSD2flag); efClear(PNS_LXD_XDflag); efClear(PNS_LXDflag); efClear(PLXD_XDflag); efClear(PHLCNDflag);
      efClear(PMSDflag); efClear(PXOSCTflag); efClear(PPSDC_PSD1flag); efClear(PMSD1flag); efClear(PLXDflag);
      efClear(PHSCDflag); efClear(PHLCADflag); efClear(PNSDflag); efClear(PTRANSDflag); efClear(PNS_LXD_XOSCTflag);
      efClear(PLXD_XOSCTflag); efClear(PHLCTDflag);

      efClear(SHSCDflag);efClear(SHSCD_setflag);efClear(LXDflag);

      efSet(doScan);

      TMODIndex=pvIndex(TMOD);
      AOUTIndex=pvIndex(AOUT);
      AINPIndex=pvIndex(AINP);
   } state readback
      }

  state readback {

    when(efTestAndClear(CLKSRCflag)) {
      fpgaWint(ssId, pVar, "registers.clksrc.count=%d", CLKSRC, 1);
    } state readback

    when(efTestAndClear(CLKRSTflag)) {
      fpgaWint(ssId, pVar, "registers.clcrst.count=%d", CLKRST, 1);
    } state readback

    when(efTestAndClear(P0FDflag)) {
      fpgaWint(ssId, pVar, "registers.p0fd.count=%d", P0FD, 1);
    } state readback

    when(efTestAndClear(P0Dflag)) {
      fpgaWint(ssId, pVar, "registers.p0d.count=%d", P0D, 1);
    } state readback

    when(efTestAndClear(LMODEflag)) {
      fpgaWint(ssId, pVar, "registers.lmode.count=%d", LMODE, 1);
    } state readback

    when(efTestAndClear(TMODEflag)) {
      fpgaWint(ssId, pVar, "registers.tmode.count=%d", TMODE, 1);
    } state readback

    when(efTestAndClear(PULSESflag)) {
      fpgaWint(ssId, pVar, "registers.pulses.count=%d", PULSES, 0);

      TMOD=0;pvPut(TMOD, SYNC);
      j=1;
      while(j==1) {
	sprintf (AOUT, "registers.pulses.count");
	pvPut(AOUT, SYNC);
	epicsThreadSleep(0.1);
	pvGet(AINP);
	//	printf("AINP= %s", AINP);
	if(atof(AINP)==0) j=0;
	//	epicsThreadSleep(1.0);
	fpga_line_num[10]=atof(AINP);
	pvPut(fpga_line_num[10]);
      }
      PULSES=0;
      pvPut(PULSES);
      efClear(PULSESflag); //This stops the when statement from triggering a second time

      PULSES_Busy=0;
      pvPut(PULSES_Busy);

      TMOD=1;pvPut(TMOD, SYNC);

    } state readback

    when(efTestAndClear(NSWAITTflag)) {
      fpgaWint(ssId, pVar, "registers.nswaitt.count=%d", NSWAITT, 1);
    } state readback

    when(efTestAndClear(PSWAITTflag)) {
      fpgaWint(ssId, pVar, "registers.pswaitt.count=%d", PSWAITT, 1);
    } state readback

    when(efTestAndClear(XWAITTflag)) {
      fpgaWint(ssId, pVar, "registers.xwaitt.count=%d", XWAITT, 1);
    } state readback

    when(efTestAndClear(PSONflag)) {
      fpgaWint(ssId, pVar, "registers.pson.count=%d", PSON, 1);
    } state readback

    when(efTestAndClear(PSD1flag)) {
      fpgaWint(ssId, pVar, "registers.psd1.count=%d", PSD1, 1);
    } state readback

    when(efTestAndClear(PSD2flag)) {
      fpgaWint(ssId, pVar, "registers.psd2.count=%d", PSD2, 1);
    } state readback

    when(efTestAndClear(PSD3flag)) {
      fpgaWint(ssId, pVar, "registers.psd3.count=%d", PSD3, 1);
    } state readback

    when(efTestAndClear(LOSCT1flag)) {
      fpgaWint(ssId, pVar, "registers.losct1.count=%d", LOSCT1, 1);
    } state readback

    when(efTestAndClear(LOSCT2flag)) {
      fpgaWint(ssId, pVar, "registers.losct2.count=%d", LOSCT2, 1);
    } state readback

    when(efTestAndClear(PSMODEflag)) {
      fpgaWint(ssId, pVar, "registers.psmode.count=%d", PSMODE, 1);
    } state readback

    when(efTestAndClear(NSONflag)) {
      fpgaWint(ssId, pVar, "registers.nson.count=%d", NSON, 1);
    } state readback

    when(efTestAndClear(NSD1flag)) {
      fpgaWint(ssId, pVar, "registers.nsd1.count=%d", NSD1, 1);
    } state readback

    when(efTestAndClear(NSD2flag)) {
      fpgaWint(ssId, pVar, "registers.nsd2.count=%d", NSD2, 1);
   } state readback

    when(efTestAndClear(NSD3flag)) {
      fpgaWint(ssId, pVar, "registers.nsd3.count=%d", NSD3, 1);
    } state readback

    when(efTestAndClear(HLCNDflag)) {
      fpgaWint(ssId, pVar, "registers.hlcnd.count=%d", HLCND, 1);
    } state readback

    when(efTestAndClear(HLCTDflag)) {
      fpgaWint(ssId, pVar, "registers.hlctd.count=%d", HLCTD, 1);
    } state readback

    when(efTestAndClear(HSCDflag)) {
      fpgaWint(ssId, pVar, "registers.hscd.count=%d", HSCD, 1);
    } state readback

    when(efTestAndClear(MSONflag)) {
      fpgaWint(ssId, pVar, "registers.mson.count=%d", MSON, 1);
    } state readback

    when(efTestAndClear(MSD1flag)) {
      fpgaWint(ssId, pVar, "registers.msd1.count=%d", MSD1, 1);
    } state readback

    when(efTestAndClear(MSD2flag)) {
      fpgaWint(ssId, pVar, "registers.msd2.count=%d", MSD2, 1);
    } state readback

    when(efTestAndClear(XOSCT1flag)) {
      fpgaWint(ssId, pVar, "registers.xosct1.count=%d", XOSCT1, 1);
    } state readback

    when(efTestAndClear(XOSCT2flag)) {
      fpgaWint(ssId, pVar, "registers.xosct2.count=%d", XOSCT2, 1);
    } state readback

    when(efTestAndClear(TRANSONflag)) {
      fpgaWint(ssId, pVar, "registers.transon.count=%d", TRANSON, 1);
    } state readback

    when(efTestAndClear(TRANSDflag)) {
      fpgaWint(ssId, pVar, "registers.transd.count=%d", TRANSD, 1);
    } state readback

    when(efTestAndClear(DIAG1flag)) {
      fpgaWint(ssId, pVar, "registers.diag1.count=%d", DIAG1, 1);
    } state readback

    when(efTestAndClear(DIAG2flag)) {
      fpgaWint(ssId, pVar, "registers.diag2.count=%d", DIAG2, 1);
    } state readback

    when(efTestAndClear(PMSD2flag)) {
      fpgaWdouble(ssId, pVar, "parameters.msd2.offset=%.18f", PMSD2, 1);
    } state readback

    when(efTestAndClear(PNS_LXD_XDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.ns_lxd.xd_offset=%.18f", PNS_LXD_XD, 1);
   } state readback

    when(efTestAndClear(PNS_LXDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.ns_lxd.offset=%.18f", PNS_LXD, 1);
    } state readback

    when(efTestAndClear(PLXD_XDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.lxd.xd_offset=%.18f", PLXD_XD, 1);
    } state readback

    when(efTestAndClear(PHLCNDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.hlcnd.offset=%.18f", PHLCND, 1);
    } state readback

    when(efTestAndClear(PMSDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.msd.offset=%.18f", PMSD, 1);
    } state readback

    when(efTestAndClear(PXOSCTflag)) {
      fpgaWdouble(ssId, pVar, "parameters.xosct.offset=%.18f", PXOSCT, 1);
    } state readback

    when(efTestAndClear(PPSDC_PSD1flag)) {
      fpgaWdouble(ssId, pVar, "parameters.psdc.psd1_offset=%.18f", PPSDC_PSD1, 1);
    } state readback

    when(efTestAndClear(PMSD1flag)) {
      fpgaWdouble(ssId, pVar, "parameters.msd1.offset=%.18f", PMSD1, 1);
    } state readback

    when(efTestAndClear(PLXDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.lxd.offset=%.18f", PLXD, 1);
    } state readback

    when(efTestAndClear(PHSCDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.hscd.offset=%.18f", PHSCD, 1);
    } state readback

    when(efTestAndClear(PHLCADflag)) {
      fpgaWdouble(ssId, pVar, "parameters.hlcad.offset=%.18f", PHLCAD, 1);
    } state readback

    when(efTestAndClear(PNSDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.nsd.offset=%.18f", PNSD, 1);
    } state readback

    when(efTestAndClear(PTRANSDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.transd.offset=%.18f", PTRANSD, 1);
    } state readback

    when(efTestAndClear(PNS_LXD_XOSCTflag)) {
      fpgaWdouble(ssId, pVar, "parameters.ns_lxd.xosct_offset=%.18f", PNS_LXD_XOSCT, 1);
    } state readback

    when(efTestAndClear(PLXD_XOSCTflag)) {
      fpgaWdouble(ssId, pVar, "parameters.lxd.xosct_offset=%.18f", PLXD_XOSCT, 1);
    } state readback

    when(efTestAndClear(PHLCTDflag)) {
      fpgaWdouble(ssId, pVar, "parameters.hlctd.offset=%.18f", PHLCTD, 1);
    } state readback

    when(efTestAndClear(SHSCDflag) || (update_hscd == 1) || efTestAndClear(SHSCD_posflag) || efTestAndClear(SHSCD_negflag)) {

      TMOD=0;pvPut(TMOD, SYNC);
      sprintf (AOUT, "parameters.%s", Param[10]);
      pvPut(AOUT, SYNC);
      epicsThreadSleep(0.1);
      pvGet(AINP);

%%    sscanf(pVar->AINP,"%lg", &pVar->CleanVal2);

	//	HSCD=CleanVal; 
	//	parameters[10]=CleanVal;
	//	pvPut(parameters[10]);
      hscd_offset=CleanVal2;

	//SHSCD = HSCD/bcf+hscd_offset;
	//	if ((SHSCD < 1e-12) && (SHSCD > -1e-12)) SHSCD=0.0;
	//	pvPut(SHSCD);
	//	efClear(SHSCDflag);

      if (update_hscd == 0) {
	hscd_temp =((SHSCD - hscd_offset)*bcf); 
%%      pVar->hscd_counts = (int)(pVar->hscd_temp + 0.5);
	//	hscd_counts=CleanVal;

	if (SHSCD_pos==1) {
	  hscd_counts = hscd_counts + SHSCD_step;
	  SHSCD_pos=0;
	  pvPut(SHSCD_pos);
	}
	if (SHSCD_neg==1) {
	  hscd_counts = hscd_counts - SHSCD_step;
	  SHSCD_neg=0;
	  pvPut(SHSCD_neg);
	}
      }
      else
      {
	hscd_counts = OldVal[29];
	update_hscd = 0;
      }

      if (hscd_counts > 0 && hscd_counts < 351934) {
	TMOD=1;pvPut(TMOD);sprintf (AOUT, "registers.hscd.count=%d", hscd_counts);pvPut(AOUT);TMOD=0;pvPut(TMOD);
	//efSet(doScan);

	// Calculate new value of hscd
	SHSCD = hscd_counts/bcf+hscd_offset;
	if ((SHSCD < 1e-12) && (SHSCD > -1e-12)) SHSCD=0.0;
	pvPut(SHSCD);
	efClear(SHSCDflag);
      }
      else
	{
	SHSCD = HSCD/bcf+hscd_offset;
	if ((SHSCD < 1e-12) && (SHSCD > -1e-12)) SHSCD=0.0;
	pvPut(SHSCD);
	efClear(SHSCDflag);
	}
      TMOD=1;pvPut(TMOD, SYNC);      
    } state readback

    when(efTestAndClear(SHSCD_setflag)) {
      printf("Old hscd.offset = %.18g\n",hscd_offset);
      PHSCD=-hscd_counts/bcf;
      pvPut(PHSCD);
      printf("New hscd.offset = %.18g\n",PHSCD);
      SHSCD_set=0; pvPut(SHSCD_set); efClear(SHSCD_setflag);
    } state readback

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
      if (Debug == 1 || Debug == 2) printf("PSD3=%d\n",PSD3);
      pvPut(PSD3);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.psd3.count=%d", PSD3, 1);efClear(PSD3flag);

      epicsThreadSleep(sleep);

      PSDC_dial = LD - PSD3_dial;
      if (Debug == 1) printf("PSDC_dial=%.12f\n",PSDC_dial);

      %% pVar->PSD1_dial = fmod((pVar->PSDC_dial+pVar->PSDC_PSD1_OFFSET),5.0/pVar->bcf);
      if (Debug == 1) printf("PSD1_dial=%.12f\n",PSD1_dial);

      PSD1 = Round(PSD1_dial/0.000000000010048);
      if (Debug == 1 || Debug == 2) printf("PSD1=%d\n",PSD1);
      pvPut(PSD1);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.psd1.count=%d", PSD1, 1);efClear(PSD1flag);

      epicsThreadSleep(sleep);

      PSD2_dial = PSDC_dial;
      if (Debug == 1) printf("PSD2_dial=%.12f\n",PSD2_dial);

      PSD2 = Round(PSD2_dial*bcf);
      if (Debug == 1 || Debug == 2) printf("PSD2=%d\n",PSD2);
      pvPut(PSD2);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.psd2.count=%d", PSD2, 1);efClear(PSD2flag);

      epicsThreadSleep(sleep);

      MSD2_dial = XD;
      if (Debug == 1) printf("MSD2_dial=%.12f\n",MSD2_dial);

      MSD2 = Round(MSD2_dial*hscf);
      if (Debug == 1 || Debug == 2) printf("MSD2=%d\n",MSD2);
      pvPut(MSD2);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.msd2.count=%d", MSD2, 1);efClear(MSD2flag);

      epicsThreadSleep(sleep);

      XOSCT_value = XD - LXD_XD_OFFSET;
      if (Debug == 1) printf("XOSCT_value=%.12f\n",XOSCT_value);

      XOSCT_dial = XOSCT_value - XOSCT_OFFSET;
      if (Debug == 1) printf("XOSCT_dial=%.12f\n",XOSCT_dial);

      %% pVar->XOSCT2_dial = pVar->XOSCT_dial - fmod(pVar->XOSCT_dial,1.0/pVar->hscf);
      if (Debug == 1) printf("XOSCT2_dial=%.12f\n",XOSCT2_dial);

      XOSCT2 = Round(XOSCT2_dial * hscf);
      if (Debug == 1 || Debug == 2) printf("XOSCT2=%d\n",XOSCT2);
      pvPut(XOSCT2);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.xosct2.count=%d", XOSCT2, 1);efClear(XOSCT2flag);

      epicsThreadSleep(sleep);

      XOSCT1_dial = XOSCT_dial - XOSCT2_dial;
      if (Debug == 1) printf("XOSCT1_dial=%.12f\n",XOSCT1_dial);

      XOSCT1 = Round(XOSCT1_dial * bcf);
      if (Debug == 1 || Debug == 2) printf("XOSCT1=%d\n",XOSCT1);
      pvPut(XOSCT1);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.xosct1.count=%d", XOSCT1, 1);efClear(XOSCT1flag);
      epicsThreadSleep(sleep);

      LOSCT_value = LD + LXD_XOSCT_OFFSET;
      if (Debug == 1) printf("LOSCT_value=%.12f\n",LOSCT_value);

      LOSCT_dial = LOSCT_value;
      if (Debug == 1) printf("LOSCT_dial=%.12f\n",LOSCT_dial);

      %% pVar->LOSCT2_dial = pVar->LOSCT_dial - fmod(pVar->LOSCT_dial,1.0/pVar->hscf);
      if (Debug == 1) printf("LOSCT2_dial=%.12f\n",LOSCT2_dial);

      LOSCT2 = Round(LOSCT2_dial * hscf);
      if (Debug == 1 || Debug == 2) printf("LOSCT2=%d\n",LOSCT2);
      pvPut(LOSCT2);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.losct2.count=%d", LOSCT2, 1);efClear(LOSCT2flag);

      epicsThreadSleep(sleep);

      LOSCT1_dial = LOSCT_dial - LOSCT2_dial;
      if (Debug == 1) printf("LOSCT1_dial=%.12f\n",LOSCT1_dial);

      LOSCT1 = Round(LOSCT1_dial * bcf);
      if (Debug == 1 || Debug == 2) printf("LOSCT1=%d\n",LOSCT1);
      pvPut(LOSCT1);
      pvFlush();
      fpgaWint(ssId, pVar, "registers.losct1.count=%d", LOSCT1, 1);efClear(LOSCT1flag);

      epicsThreadSleep(sleep);

      // Wait for the fpga to process before allowing the busy record to be set to done.
      // Should calc lxd_rbv instead. This could be removed?
      epicsThreadSleep(1.0);

      TMOD=0;pvPut(TMOD);pvFlush();
      fpga_line_num[17]=fpgaRint(ssId, pVar, "psd3", 17); pvPut(fpga_line_num[17]);
      fpga_line_num[15]=fpgaRint(ssId, pVar, "psd1", 15); pvPut(fpga_line_num[15]);
      fpga_line_num[16]=fpgaRint(ssId, pVar, "psd2", 16); pvPut(fpga_line_num[16]);
      fpga_line_num[32]=fpgaRint(ssId, pVar, "msd2", 32); pvPut(fpga_line_num[32]);
      fpga_line_num[34]=fpgaRint(ssId, pVar, "xosct2", 34); pvPut(fpga_line_num[34]);
      fpga_line_num[33]=fpgaRint(ssId, pVar, "xosct1", 33); pvPut(fpga_line_num[33]);
      fpga_line_num[19]=fpgaRint(ssId, pVar, "losct2", 19); pvPut(fpga_line_num[19]);
      fpga_line_num[18]=fpgaRint(ssId, pVar, "losct1", 18); pvPut(fpga_line_num[18]);
      TMOD=1;pvPut(TMOD);pvFlush();

      // Should put this part into a function then add a reference from the general scanning section.
      MSD2_dial = fpga_line_num[32]/hscf;
      if (Debug == 1) printf("LXD_RBV:MSD2_dial=%.12f\n",MSD2_dial);

      PSD1_dial = fpga_line_num[15]*10.048e-12;
      if (Debug == 1) printf("LXD_RBV:PSD1_dial=%.12f\n",PSD1_dial);

      PSD2_dial = fpga_line_num[16]/bcf;
      if (Debug == 1) printf("LXD_RBV:PSD2_dial=%.12f\n",PSD2_dial);

      PSD3_dial = fpga_line_num[17]/hscf;
      if (Debug == 1) printf("LXD_RBV:PSD3_dial=%.12f\n",PSD3_dial);

      PSDC_temp1 = PSD1_dial - PSD2_dial - parameters[7];
%%    pVar->PSDC_temp2 = floor((pVar->PSDC_temp1/(5/pVar->bcf))+0.5)*(5/pVar->bcf);
      PSDC_t1 = PSDC_temp1 - PSDC_temp2;
      PSDC_dial = PSDC_t1 + PSD2_dial;
      if (Debug == 1) printf("LXD_RBV:PSDC_dial=%.12f\n",PSDC_dial);

      PSD_dial = PSD3_dial + PSDC_dial;
      if (Debug == 1) printf("LXD_RBV:PSD_dial=%.12f\n",PSD_dial);

      LXD_RBV = (MSD2_dial - PSD_dial) + parameters[9];
      if ((LXD_RBV <= 1e-12) && (LXD_RBV >= -1e-12)) LXD_RBV=0.0;
      pvPut(LXD_RBV, SYNC);
      if (Debug == 1) printf("LXD_RBV=%.12f\n",LXD_RBV);

      LXD_Busy=0;
      pvPut(LXD_Busy); pvFlush();

    } state readback

    // Do the periodic scan if nothing else is happening
    when((efTest(doScan)) && (SCAN != 0)) {
      TMOD=0;pvPut(TMOD);
      for(i=0;i<39;i++) {
	sprintf (AOUT, "registers.%s.count", Mnemonic[i]);
	pvPut(AOUT, SYNC);
	epicsThreadSleep(0.01);
	pvGet(AINP);

%%      sscanf(pVar->AINP,"%d", &pVar->CleanVal);

	// Need to trigger updates of other variables
	OldVal[i]=fpga_line_num[i];
	//	if (OldVal[i] != CleanVal) printf("%s changed\n",Mnemonic[i]);
	//	hscd_temp =((SHSCD - hscd_offset)*bcf); 
	//%%      pVar->hscd_counts = (int)(pVar->hscd_temp + 0.5);	
	//	if ((i == 29) && (hscd_counts != CleanVal)) {
	//	  update_hscd=1;
	//	}
	if (i==29) {
	  SHSCD = CleanVal/bcf+hscd_offset;
	  if ((SHSCD < 1e-12) && (SHSCD > -1e-12)) SHSCD=0.0;
	  pvPut(SHSCD);
	  efClear(SHSCDflag);
	}

	fpga_line_num[i] = CleanVal;
	pvPut(fpga_line_num[i]);
      }
      i=0;
      for(i=0;i<17;i++) {
	sprintf (AOUT, "parameters.%s", Param[i]);
	pvPut(AOUT, SYNC);
	pvGet(AINP);

%%      sscanf(pVar->AINP,"%lg", &pVar->CleanVal2);
	parameters[i] = CleanVal2;

	pvPut(parameters[i]);
      }
      TMOD=1;pvPut(TMOD, SYNC);
      efClear(doScan);
    } state readback
	}
}

ss scanrate {
  state rate {
    when(SCAN != 0) {
      s=0;
      while (s < SCAN) {
	epicsThreadSleep(1);
	s++;
      }     
      efSet(doScan);
   } state rate
	}
}

%{
// This function rounds a double to a specified increment.
double Round_Up(double value, double inc)
{
  return (ceil(value/inc)*inc);
}
// This rounds a double and changes it to an integer
int Round(double value)
{
  return ((int) floor(value+0.5));
}
 void fpgaWint(SS_ID ssId, struct UserVar *pVar,char *cmd, int value, int scan)
{
  //pVar->TMOD=1;
  //seq_pvPut(ssId,pVar->TMODIndex, 2);
  
  sprintf(pVar->AOUT, cmd, value);
  seq_pvPut(ssId, pVar->AOUTIndex, 2);

  // Scan all PV's if scan=1
  if (scan) seq_efSet(ssId, doScan);

  return;
}
 void fpgaWdouble(SS_ID ssId, struct UserVar *pVar,char *cmd, double value, int scan)
{

  
  sprintf(pVar->AOUT, cmd, value);
  seq_pvPut(ssId, pVar->AOUTIndex, 2);

  // Scan all PV's if scan=1
  if (scan) seq_efSet(ssId, doScan);

  return;
}
 int fpgaRint(SS_ID ssId, struct UserVar *pVar, char *cmd, int i)
{
  int temp;

  sprintf (pVar->AOUT, "registers.%s.count", cmd);
  seq_pvPut(ssId, pVar->AOUTIndex, 1);

  epicsThreadSleep(0.01);
  
  seq_pvGet(ssId, pVar->AINPIndex, 2);
  //sscanf(pVar->AINP,"%d", &temp);
  temp=atoi(pVar->AINP);
  //pVar->fpga_line_num[i] = temp;
  //seq_pvPut(ssId, pVar->fpga_line_num[i], 2);

  //printf("%s %d %d\n", cmd, i, pVar->fpga_line_num[i]);
  //printf("%s %d %d\n", cmd, i, temp);

  return temp;
}
}%

