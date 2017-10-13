MODULE_NAME='ETC Paradigm Lighting' (DEV VIRTUAL, DEV REAL, CHAR cPRESET_NAMES[10][25])
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 11:33:16        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
*)    
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

#IF_DEFINED 'VERY DEFINE WOW'
REAL	=	5001:1:0
VIRTUAL	=	33001:1:0
#END_IF
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT


//TIMELINE STUFF
tlDEV_POLL		=	1
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
#IF_DEFINED 'SO VARIABLE'
VOLATILE CHAR cPRESET_NAMES[10][25]
#END_IF

//SYSTEM STUFF
VOLATILE INTEGER nCOMMANDS_MISSED						//USED TO DETECT IF THE SYSTEM HAS GONE OFFLINE
VOLATILE INTEGER bSTRING_SET_PRESET 						//USED TO PREVENT THE LIGHTING SYSTEM RESPONSES FROM SETTING A PRESET

VOLATILE INTEGER nBUTTON_CHANNELS[] = {1,2,3,4,5,6,7,8,9,10}			//SNAPI LIGHTING SYSTEM KEYPAD CHANNELS

//TL STUFF
VOLATILE LONG lTIMES[] = {30000,2000,2000,2000,2000,2000,2000,2000,2000,2000}	//TIMES TO POLL THE LIGHTING SYSTEM
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE
([VIRTUAL,1]..[VIRTUAL,10])
(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

#INCLUDE 'SNAPI'
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[REAL]
{
    ONLINE:
    {
	SEND_COMMAND DATA.DEVICE,'SET BAUD 9600,N,8,1 485 DISABLE'
	TIMELINE_CREATE(tlDEV_POLL,lTIMES,LENGTH_ARRAY(lTIMES),TIMELINE_RELATIVE,TIMELINE_REPEAT)
	ON[VIRTUAL,DATA_INITIALIZED]
    }
    STRING:
    {
	LOCAL_VAR CHAR cINPUT_BUFFER[100]
	LOCAL_VAR INTEGER nLOOP					//USED FOR THE FOR LOOP
	
	cINPUT_BUFFER = "cINPUT_BUFFER,DATA.TEXT"		//LOAD THE INPUT BUFFER
	
	ON[VIRTUAL,DEVICE_COMMUNICATING]
	nCOMMANDS_MISSED = 0					//CLEAR THE COMMANDS MISSED TRACKER
	
	IF(FIND_STRING(cINPUT_BUFFER,"$0D",1))			//INCOMING STRING IS COMPLETE
	{
	    IF(FIND_STRING(cINPUT_BUFFER,'pst act',1) || FIND_STRING(cINPUT_BUFFER,'Activated',1))	//A PRESET RECALL HAS HAPPENED
	    {
		
		FOR(nLOOP = 1; nLOOP < 11;nLOOP++)
		{
		    IF(FIND_STRING(cINPUT_BUFFER,cPRESET_NAMES[nLOOP],1))				//IF A PARTICULAR PRESET NAME IS FOUND
		    {
			ON[VIRTUAL,nBUTTON_CHANNELS[nLOOP]]
			bSTRING_SET_PRESET = nLOOP
			CLEAR_BUFFER cINPUT_BUFFER
		    }
		}
	    }
	    
	    CLEAR_BUFFER cINPUT_BUFFER
	}
    }
}

TIMELINE_EVENT[tlDEV_POLL]
{
    IF(TIMELINE.SEQUENCE == 1)
    {
	nCOMMANDS_MISSED++
	IF(nCOMMANDS_MISSED > 5)
	{
	    OFF[VIRTUAL,DEVICE_COMMUNICATING]
	}
    }
    SEND_STRING REAL,"'pst get ',cPRESET_NAMES[TIMELINE.SEQUENCE],$0D"
}

CHANNEL_EVENT[VIRTUAL,nBUTTON_CHANNELS]
{
    ON:
    {
	IF(bSTRING_SET_PRESET != GET_LAST(nBUTTON_CHANNELS))						//ONLY SEND A PRESET CHANGE IT IT WAS NOT CAUSED BY A INCOMING STRING
	{
	    SEND_STRING REAL,"'pst act ',cPRESET_NAMES[GET_LAST(nBUTTON_CHANNELS)],$0D"			//SEND THE PRESET CHANGE STRIN
	}
    }
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
