program Mount_sample("P=14BMC:")

/*  
 *
 *  Robert Henning
 *  March 20, 2004
*/

%% #include <math.h>

double dz_drive; assign  dz_drive to "{P}dz.VAL"; monitor dz_drive;
evflag dz_drive_mon; sync dz_drive dz_drive_mon;

double dz_rbv;   assign  dz_rbv   to "{P}dz.RBV"; monitor dz_rbv;
evflag dz_rbv_mon;   sync dz_rbv   dz_rbv_mon;

int dz_done; assign  dz_done to "{P}dz.DMOV"; monitor dz_done;
evflag dz_done_mon;   sync dz_done   dz_done_mon;

double bsz_drive; assign  bsz_drive to "{P}bsz.VAL"; monitor bsz_drive;
evflag bsz_drive_mon; sync bsz_drive bsz_drive_mon;

double bsz_rbv;   assign  bsz_rbv   to "{P}bsz.RBV"; monitor bsz_rbv;
evflag bsz_rbv_mon;   sync bsz_rbv   bsz_rbv_mon;

int bsz_done; assign  bsz_done to "{P}bsz.DMOV"; monitor bsz_done;
evflag bsz_done_mon;   sync bsz_done   bsz_done_mon;

double kappa_drive; assign  kappa_drive to "{P}kappa.VAL"; monitor kappa_drive;
evflag kappa_drive_mon; sync kappa_drive kappa_drive_mon;

double kappa_rbv;   assign  kappa_rbv   to "{P}kappa.RBV"; monitor kappa_rbv;
evflag kappa_rbv_mon;   sync kappa_rbv   kappa_rbv_mon;

int kappa_done; assign  kappa_done to "{P}kappa.DMOV"; monitor kappa_done;
evflag kappa_done_mon;   sync kappa_done   kappa_done_mon; 

int sm; assign sm to "{P}Sample_mount.VAL"; monitor sm;
evflag sm_mon; sync sm sm_mon;

int sd; assign sd to "{P}Sample_done.VAL"; monitor sd;
evflag sd_mon; sync sd sd_mon; 

float dz_mp; assign dz_mp to "{P}dz_mount_pos.VAL"; monitor dz_mp;
evflag dz_mp_mon; sync dz_mp dz_mp_mon; 

float dz_op; assign dz_op to "{P}DETECTOR_DISTANCE.VAL"; monitor dz_op;
evflag dz_op_mon; sync dz_op dz_op_mon; 

float bsz_mp; assign bsz_mp to "{P}bsz_mount_pos.VAL"; monitor bsz_mp;
evflag bsz_mp_mon; sync bsz_mp bsz_mp_mon; 

float bsz_op; assign bsz_op to "{P}DETECTOR_BEAMSTOP.VAL"; monitor bsz_op;
evflag bsz_op_mon; sync bsz_op bsz_op_mon; 

float kappa_mp; assign kappa_mp to "{P}kappa_mount_pos.VAL"; monitor kappa_mp;
evflag kappa_mp_mon; sync kappa_mp kappa_mp_mon; 

float dz_rbv_cutoff; assign dz_rbv_cutoff to "{P}dz_rbv_cutoff.VAL"; monitor dz_rbv_cutoff;
evflag dz_rbv_cutoff_mon; sync dz_rbv_cutoff dz_rbv_cutoff_mon; 

float bsz_rbv_cutoff; assign bsz_rbv_cutoff to "{P}bsz_rbv_cutoff.VAL"; monitor bsz_rbv_cutoff;
evflag bsz_rbv_cutoff_mon; sync bsz_rbv_cutoff bsz_rbv_cutoff_mon; 

float dz_soft_low; assign dz_soft_low to "{P}dz.LLM"; monitor dz_soft_low;
evflag dz_soft_low_mon; sync dz_soft_low dz_soft_low_mon;

int temp; int temp2; int working;

ss Mount {
    state mount {
        when(sm == 1 && working == 0 && delay(0.1)) { 
	   pvGet(dz_mp);
	   pvGet(dz_rbv);
	   if (dz_rbv < dz_mp) {
  	      dz_drive = dz_mp;
	      pvPut(dz_drive);
	   }
           temp = 1;
	} state mount
	when(dz_rbv > dz_rbv_cutoff && temp == 1 && delay(0.1)) {
	   pvGet(bsz_mp);
	   bsz_drive = bsz_mp;
 	   pvPut(bsz_drive);
	   pvGet(kappa_mp);
	   kappa_drive = kappa_mp;
 	   pvPut(kappa_drive);
	   temp = 0;
	} state mount
    }
}
ss Done {
    state done {
        when(sd == 1  && working == 0 && delay(0.1)) { 
	   kappa_drive = 0;
	   pvPut(kappa_drive);
	   pvGet(bsz_op);
           bsz_drive = bsz_op;
           pvPut(bsz_drive);
	   temp2 = 1;
        } state done
	when(dz_soft_low <= dz_op && kappa_rbv > -20 && temp2 == 1 && delay(0.1)) {
	   pvGet(dz_op);
	   dz_drive = dz_op;
 	   pvPut(dz_drive);
	   temp2 = 0;
	} state done
    }
}
ss Status {
    state status {
	when (delay(0.1)) {
	   if (dz_done == 1 && bsz_done == 1 && kappa_done == 1) working=0;
	   else working = 1;
	} state status
    }
}
