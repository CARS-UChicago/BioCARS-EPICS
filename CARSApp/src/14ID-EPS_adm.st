/* This program controls login process for MEDM user to be valve operator */ 

program EPS_vlv("P=14IDA:")

 %% #include <string.h>

/*  ID and Password -- preset at initiate state of this program  */
 string usrID;
 string pwd;
 
/*  ID -- input from MEDM screen by user */
 string  usrID_inp;
 assign  usrID_inp       to "{P}eps_usrID_inp";
 monitor usrID_inp;
 
 string  usrID_inp_copy;  /* duplication of usrID_inp  */
 
 /*  Password -- input by user on MEDM screen */ 
  string  pwd_inp;                 
  assign  pwd_inp         to "{P}eps_pwd_inp";
  monitor pwd_inp;
  
  string  pwd_inp_copy;   /* duplication of pwd_inp  */
  

/*  -- quitADM_RQ -- Quit button pressed by user */                                 
 unsigned short quitADM_RQ;      
 assign         quitADM_RQ   to "{P}eps_quitADM-RQ.VAL";   
 monitor        quitADM_RQ;

/* Remote valve operation permission. It can be offered ONLY: */
/* if beam is OFF and no others are trying to manage the beamline  */
 unsigned short adm_PRMT;        
 assign         adm_PRMT        to "{P}eps_adm_PRMT.VAL";
 monitor        adm_PRMT; 
 
 /* Valve-OP authorized  */
 unsigned short login_OK;   
 assign         login_OK       to  "{P}eps_login_OK.VAL";  
                                                                  
/* Board containing boxes for user to input userID and pwd */
/* It is visible at value equal to 1  */
 unsigned short sign_board;   
 assign         sign_board   to "{P}eps_sign_board.VAL";    

 
                                                                           
/*  -----------------Begin State statements-------------- */
ss login_vlvOP
{
  state init 
  {
    when () 
    {      
      strcpy(usrID, "adm");  strcpy(pwd,"adm");  /* Preset userID and password */
    }
  	state Do_logout
  }
  
  state Do_logout   
  {  
    entry {
      login_OK=FALSE;        pvPut(login_OK);   /* drop off ADM mode */
      sign_board=FALSE;      pvPut(sign_board); /* close sign_board for login */
      strcpy(usrID_inp,"");  pvPut(usrID_inp);  strcpy(usrID_inp_copy,"");
      strcpy(pwd_inp,"");    pvPut(pwd_inp);    strcpy(pwd_inp_copy,"");
           }
    when(adm_PRMT && delay(1)) 
        {  sign_board=TRUE;     pvPut(sign_board);   }
    state try_login
   }    
  
  state try_login   
  { 
    option -t;   /* cause timer not to reset upon reentry */
   
    when (!adm_PRMT)  {}  state Do_logout  /* Quit signIn when lost adm-PRMT  */ 
    when (delay(30))  {}  state Do_logout  /* Set 60-sec time limit to complete logIn */
      
      /*  Go to ADM mode if both ID&PWD exam passed */
    when ((strcmp(usrID_inp_copy,usrID)==0)&&(strcmp(pwd_inp_copy,pwd)==0))  
    { 
      login_OK=TRUE;  pvPut(login_OK);        
    }        
    state In_adm
    
    /* Latch non-null string input for userID exam */
    when ((!strcmp(usrID_inp,usrID_inp_copy)==0)&& (!strcmp(usrID_inp,"")==0))
         {strcpy(usrID_inp_copy,usrID_inp);   strcpy(usrID_inp,""); pvPut(usrID_inp); }
    state try_login
    
    /* Latch non-null string input for password exam */
    when ((!strcmp(pwd_inp,pwd_inp_copy)==0)&& (!strcmp(pwd_inp,"")==0))
         {strcpy(pwd_inp_copy,pwd_inp);    strcpy(pwd_inp,""); pvPut(pwd_inp);  }
          
    state try_login
  }
  
  state In_adm  /* Jobs within administration */
   {
     entry {         
         sign_board=FALSE; pvPut(sign_board);  /* close sign_board */
            }   
         
     when (!adm_PRMT)  {}             
     state Do_logout	/* Get out due to lost ADM-permission */
  
     when (quitADM_RQ) {}            
     state Do_logout     /* Quit administration when QUIT button is pressed */
   
     when (delay(60)) {}             
     state Do_logout  	/* Automatically quit after 120-sec timeout */  
    }  
}   
