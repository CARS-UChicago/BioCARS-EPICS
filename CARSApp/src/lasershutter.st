program laserShutter("P=14IDB:")
/*
* Robert Henning 2/2010
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
//int   debugLevel;             
//assign debugLevel  to "{P}LSDebugLevel.VAL";
//monitor debugLevel;

// IDB_search: 1=station has been searched
int IDB_search;
/* assign IDB_search to "PA:14ID:B_SEARCHED.VAL"; */
assign IDB_search to "PA:14ID:STA_B_SEARCHED_PL.VAL";
monitor IDB_search; 

// Laser_shutter_status: 1=shutter is closed
int Laser_shutter_status;
assign Laser_shutter_status to "{P}B1Bi0.VAL";
monitor Laser_shutter_status;

// Trigger to open shutter
int Laser_shutter_open;
assign Laser_shutter_open to "{P}lshutter.PROC";

int Laser_shutter_auto;
assign Laser_shutter_auto to "{P}lshutter_auto";
monitor Laser_shutter_auto;

ss laserShutter{
	state init {
		when() {
		} state scan 
	} 

	state scan {
        	when(Laser_shutter_auto == 1 && delay(5.0)) {
			if ((IDB_search==1) && (Laser_shutter_status==1)) {
				Laser_shutter_open=1;
				pvPut(Laser_shutter_open);
				epicsThreadSleep(15.0);
			}
		} state scan
	}
}


