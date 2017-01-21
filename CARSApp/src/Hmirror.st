/* -*-c-*- */
program Hmirror("P=14IDA:, mir= mir2, Y1=m9, Y2=m10, Y3=m11, X1=m12, X2=m13 GEOM = 1")

/*  
* This sequencer program works with mirror.db.
* For use with Sesso/Oxford Mirror A and B at Sector 15ID
* Both Mirrors use the same program.  However geometry constants are
* depending what the GEOM switch is set to.
* Timothy Graber Aug. 2001
* 
* Modified to be used for the horizontal mirror at 14-ID.
* Changes from vertical mirror configuration:
* -This mirror has two vertical motors on the upstream end and one on the downstream.
* -"Theta" has been defined as the horizontal angle
*
* Robert Henning March 2007
*/

%% #include <math.h>
#define Debug(L,FMT,V...) {  if(L == debugLevel) \
                        { printf(FMT,##V); } }

option +r;
option -a;

/* The real motors */
double y1_drive;  assign  y1_drive  to "{P}{Y1}.VAL";  monitor y1_drive;
double y2_drive;  assign  y2_drive  to "{P}{Y2}.VAL";  monitor y2_drive;
double y3_drive;  assign  y3_drive  to "{P}{Y3}.VAL";  monitor y3_drive;
double y1_rbv;    assign  y1_rbv    to "{P}{Y1}.RBV";  monitor y1_rbv;
double y2_rbv;    assign  y2_rbv    to "{P}{Y2}.RBV";  monitor y2_rbv;
double y3_rbv;    assign  y3_rbv    to "{P}{Y3}.RBV";  monitor y3_rbv;

evflag y1_drive_mon;   sync y1_drive  y1_drive_mon;
evflag y1_rbv_mon;     sync y1_rbv    y1_rbv_mon;
evflag y2_drive_mon;   sync y2_drive  y2_drive_mon;
evflag y2_rbv_mon;     sync y2_rbv    y2_rbv_mon;
evflag y3_drive_mon;   sync y3_drive  y3_drive_mon;
evflag y3_rbv_mon;     sync y3_rbv    y3_rbv_mon;

double x1_drive;  assign  x1_drive  to "{P}{X1}.VAL";  monitor x1_drive;
double x2_drive;  assign  x2_drive  to "{P}{X2}.VAL";  monitor x2_drive;
double x1_rbv;    assign  x1_rbv    to "{P}{X1}.RBV";  monitor x1_rbv;
double x2_rbv;    assign  x2_rbv    to "{P}{X2}.RBV";  monitor x2_rbv;

evflag x1_drive_mon;   sync x1_drive  x1_drive_mon;
evflag x1_rbv_mon;     sync x1_rbv    x1_rbv_mon;
evflag x2_drive_mon;   sync x2_drive  x2_drive_mon;
evflag x2_rbv_mon;     sync x2_rbv    x2_rbv_mon;

/* Pseudomotors */
/* Pseudomotor Y mirror up/dwn */
double pmy_drive; assign pmy_drive  to "{P}{mir}Y.DVAL";    monitor pmy_drive;
double pmy_move;  assign pmy_move   to "{P}{mir}YMove";    monitor pmy_move;
double pmy_rbv;   assign pmy_rbv    to "{P}{mir}YRdbk";
double pmy_set;   assign pmy_set    to "{P}{mir}Y.SET";

/* Pseudomotor X mirror inboard/outboard */
double pmx_drive; assign pmx_drive  to "{P}{mir}X.DVAL";    monitor pmx_drive;
double pmx_move;  assign pmx_move   to "{P}{mir}XMove";    monitor pmx_move;
double pmx_rbv;   assign pmx_rbv    to "{P}{mir}XRdbk";
double pmx_set;   assign pmx_set    to "{P}{mir}X.SET";

/* Pseudomotor theta angle */
double pmth_drive;  assign pmth_drive   to "{P}{mir}Th.DVAL";    monitor pmth_drive;
double pmth_move;   assign pmth_move    to "{P}{mir}ThMove";    monitor pmth_move;
double pmth_rbv;    assign pmth_rbv     to "{P}{mir}ThRdbk";
double pmth_set;    assign pmth_set     to "{P}{mir}Th.SET";

/* Pseudomotor chi angle */
double pmchi_drive;  assign pmchi_drive   to "{P}{mir}Chi.DVAL";    monitor pmchi_drive;
double pmchi_move;   assign pmchi_move    to "{P}{mir}ChiMove";    monitor pmchi_move;
double pmchi_rbv;    assign pmchi_rbv     to "{P}{mir}ChiRdbk";
double pmchi_set;    assign pmchi_set     to "{P}{mir}Chi.SET";

/*3456789012345678901234567890123456789012345678901234567890123456789012345678901234567890*/
/* Pseudomotor vertical angle */
double pmvangle_drive; assign pmvangle_drive to "{P}{mir}Vangle.VAL"; 
monitor pmvangle_drive;
double pmvangle_move;  assign pmvangle_move  to "{P}{mir}VangleMove"; 
monitor pmvangle_move;
double pmvangle_rbv;   assign pmvangle_rbv   to "{P}{mir}VangleRdbk";
double pmvangle_set;   assign pmvangle_set   to "{P}{mir}Vangle.SET";

int	   debugLevel;	 assign debugLevel  to "{P}{mir}debugLevel.VAL";monitor debugLevel;
int	   realDone;	 assign realDone  to "{P}{mir}CompDone.VAL";monitor realDone;
int	   pseudoDone;	 assign pseudoDone  to "{P}{mir}PseudoDone.VAL";monitor pseudoDone;

evflag real_done_mon; sync realDone real_done_mon;
evflag pmy_move_mon; sync pmy_move pmy_move_mon;
evflag pmx_move_mon; sync pmx_move pmx_move_mon;
evflag pmchi_move_mon; sync pmchi_move pmchi_move_mon;
evflag pmth_move_mon; sync pmth_move pmth_move_mon;
evflag pmvangle_move_mon; sync pmvangle_move pmvangle_move_mon;


/* Geometry offsets */
double yPosZLength; assign yPosZLength  to "{P}{mir}yPosZ"; 
monitor yPosZLength;

double yPosXLength;  assign yPosXLength    to "{P}{mir}yPosX";   
monitor yPosXLength;

double mirCntLength;  assign mirCntLength    to "{P}{mir}CntLength";   
monitor mirCntLength;


double radConv; /* radians to miliradians */
double dtor; /* degrees to radians*/

%%char *mirror_pmacGEOM;
short GEOM; 
double theta_sgn;
double c1; 
double c2;
double c3;
double c4;

ss mirror {
    state init {
        when() {
            dtor = 4.*atan(1.)/180.;
            radConv =1.e-3;
            efClear(pmy_move_mon); /* Don't move motors on initialization */
            efClear(pmx_move_mon);
            efClear(pmth_move_mon);
            efClear(pmchi_move_mon);
            efClear(pmvangle_move_mon);
%{
	    mirror_pmacGEOM = seq_macValueGet(ssId,"GEOM");
	    pVar->GEOM = 1;
	    if (*mirror_pmacGEOM == '2') pVar->GEOM = 2;
}%
			if (GEOM == 1) {
				yPosZLength = 1045.0; /* Mirror A geometry parameters*/
				pvPut(yPosZLength);
				yPosXLength = 240.0;
				pvPut(yPosXLength);
				mirCntLength =522.5;
				pvPut(mirCntLength);
				theta_sgn = -1.0;
				c1 = yPosZLength-mirCntLength;
			} 
			else {
				yPosZLength = 760.0; /* Mirror B geometry parameters*/
				pvPut(yPosZLength);
				yPosXLength = 240.0;
				pvPut(yPosXLength);
				mirCntLength =410.0;
				pvPut(mirCntLength);
				theta_sgn = -1.0;
				c1 = yPosZLength-mirCntLength;
			}
        } state monitor_changes
    }
/*3456789012345678901234567890123456789012345678901234567890123456789012345678901234567890*/
    state monitor_changes {
	when(efTestAndClear(pmy_move_mon)) {
		y1_drive = pmy_drive-mirCntLength*tan(pmvangle_rbv*radConv);
		y2_drive = pmy_drive+c1*tan(pmvangle_rbv*radConv)-yPosXLength*tan(pmchi_rbv*radConv)/2.;
		y3_drive = pmy_drive+c1*tan(pmvangle_rbv*radConv)+yPosXLength*tan(pmchi_rbv*radConv)/2.;
		pvPut(y1_drive);
		pvPut(y2_drive);
		pvPut(y3_drive);
		pseudoDone = 0;
		pvPut(pseudoDone);
		Debug(1, "y1:%f y2:%f y3:%f reDn:%d psDn:%d\n", y1_drive, y2_drive, y3_drive, realDone, pseudoDone);
    	} state monitor_changes
	when(efTestAndClear(pmx_move_mon)) {
		x1_drive = pmx_drive+mirCntLength*tan(pmth_rbv*radConv);
		x2_drive = pmx_drive-c1*tan(pmth_rbv*radConv);
		pvPut(x1_drive);
		pvPut(x2_drive);
		pseudoDone = 0;
		pvPut(pseudoDone);
		Debug(1, "x1:%f x2:%f reDn:%d psDn:%d\n", x1_drive, x2_drive, realDone, pseudoDone);
    	} state monitor_changes
     	when(efTestAndClear(pmth_move_mon)) {
		x1_drive = pmx_rbv-mirCntLength*tan(theta_sgn*pmth_drive*radConv);
		x2_drive = pmx_rbv+c1*tan(theta_sgn*pmth_drive*radConv);
		pvPut(x1_drive);
		pvPut(x2_drive);
		pseudoDone = 0;
		pvPut(pseudoDone);
		Debug(1, "x1:%f x2:%f reDn:%d psDn:%d\n", x1_drive, x2_drive, realDone, pseudoDone);
     	} state monitor_changes
     	when(efTestAndClear(pmchi_move_mon)) {
		y2_drive = pmy_rbv+c1*tan(pmvangle_rbv*radConv)-yPosXLength*tan(pmchi_drive*radConv)/2.;
		y3_drive = pmy_rbv+c1*tan(pmvangle_rbv*radConv)+yPosXLength*tan(pmchi_drive*radConv)/2.;
		pvPut(y2_drive);
		pvPut(y3_drive);
		pseudoDone = 0;
		pvPut(pseudoDone);
		Debug(1, "y1:%f y2:%f y3:%f reDn:%d psDn:%d\n", y1_drive, y2_drive, y3_drive, realDone, pseudoDone);
     	} state monitor_changes
     	when(efTestAndClear(pmvangle_move_mon)) {
		y1_drive = pmy_rbv-mirCntLength*tan(pmvangle_drive*radConv);
		y2_drive = pmy_rbv+c1*tan(pmvangle_drive*radConv)-yPosXLength*tan(pmchi_rbv*radConv)/2.;
		y3_drive = pmy_rbv+c1*tan(pmvangle_drive*radConv)+yPosXLength*tan(pmchi_rbv*radConv)/2.;
		pvPut(y1_drive);
		pvPut(y2_drive);
		pvPut(y3_drive);
		pseudoDone = 0;
		pvPut(pseudoDone);
		Debug(1, "y1:%f y2:%f y3:%f reDn:%d psDn:%d\n", y1_drive, y2_drive, y3_drive, realDone, pseudoDone);
     	} state monitor_changes

/* The motor readbacks have changed update readbacks */


     when(efTestAndClear(y1_rbv_mon) || efTestAndClear(y2_rbv_mon) || efTestAndClear(y3_rbv_mon) || efTestAndClear(x1_rbv_mon)|| efTestAndClear(x2_rbv_mon) ) {
		pseudoDone = 0;
		pvPut(pseudoDone);
    } state update_readbacks
     
     when(efTestAndClear(real_done_mon)) {
     	   if ((realDone == 1)) {
     	   	pseudoDone = 1; 
		pvPut(pseudoDone);
     	   	Debug(2, "REAL MOTORS DONE\n");
	   } 
	   else {
    	   	Debug(2, "REAL MOTORS RUNNING\n");
	   }
     } state update_readbacks
    }
/*
*   Needed to add the pseudoDone parameter so that the drive values of the pseudo motors would not be set 
*   until the last pseudo motor readback update. When all the real motors are done set pseudoDone = 1
*   update readbacks and pvPut pseudoDone to update the drive values  
*
*/
    state update_readbacks {
        when() {
		pmy_rbv = ((yPosZLength-mirCntLength)*y1_rbv+(y2_rbv+y3_rbv)*mirCntLength/2.0)/(yPosZLength);
		pmx_rbv = ((yPosZLength-mirCntLength)*x1_rbv+x2_rbv*mirCntLength)/(yPosZLength);
		pmth_rbv = atan((x1_rbv-x2_rbv)/yPosZLength)/radConv;
		pmchi_rbv = atan((y3_rbv-y2_rbv)/yPosXLength)/radConv;
		pmvangle_rbv = atan(((y3_rbv+y2_rbv)/2.0-y1_rbv)/yPosZLength)/radConv;
		pvPut(pmy_rbv);
		pvPut(pmx_rbv);
		pvPut(pmth_rbv);
		pvPut(pmchi_rbv);
		pvPut(pmvangle_rbv);
		pvPut(pseudoDone);
		Debug(1, "y1:%f y2:%f y3:%f x1:%f x2:%f\n", y1_rbv, y2_rbv, y3_rbv, x1_rbv, x2_rbv);
		Debug(1, "pmy:%f pmth:%f pmchi:%f pmvangle:%f dmov:%d psDn:%d\n", pmy_rbv, pmth_rbv, pmchi_rbv, pmvangle_rbv, realDone, pseudoDone);
      } state monitor_changes
    } 
}


