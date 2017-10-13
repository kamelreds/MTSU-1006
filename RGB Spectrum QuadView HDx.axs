MODULE_NAME='RGB Spectrum QuadView HDx' (dev VIRTUAL, DEV REAL)
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
#IF_DEFINED 'SUCH DEFINE WOW'
VIRTUAL	=	33001:1:0
REAL	=	5001:1:0
#END_IF

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

//TIMELINES
tlDEV_POLL		=	1			//TIMELINE TO POLL

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

VOLATILE INTEGER nBUTTON_CHANNELS[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}	//ALL THE POSSABLE PRESETS

VOLATILE INTEGER nDEV_CMDS_MISSED						//TRACKS THE NUMBER OF FAILED COMMANDS

VOLATILE INTEGER nOUTPUT_ENABLED
VOLATILE INTEGER nLAST_VIEW

VOLATILE LONG lDEV_POLL_TIMES[] = {45000}					//15 SECONDS FOR LAMP POLL THEN .5 SECONDS FOR POWER POLL
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE
([VIRTUAL,1]..[VIRTUAL,15])
(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START
 WAIT 600 nOUTPUT_ENABLED = TRUE
 #INCLUDE 'SNAPI'
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[REAL]
{
    ONLINE:
    {
	SEND_COMMAND DATA.DEVICE,"'SET BAUD 115200,N,8,1'"
	//TIMELINE_CREATE(tlDEV_POLL,lDEV_POLL_TIMES,LENGTH_ARRAY(lDEV_POLL_TIMES),TIMELINE_RELATIVE,TIMELINE_REPEAT)	//START POLLING THE PROJ
    }
    STRING:
    {
	nDEV_CMDS_MISSED = 0							//THE PROJ IS CONNECTED SO ZERO THE MISSED CMDS COUNTER
	ON[VIRTUAL,252]								//SET THE RMS DEVICE ONLINE FLAG
	ON[VIRTUAL,251]
	SELECT
	{
	    ACTIVE(FIND_STRING(DATA.TEXT,'QVHD COMPACT FLASH BOOT LOADER',1)):	//WE CANT SEND STRING DURING BOOT, BECAUSE IT KILLS IT
	    {
		nOUTPUT_ENABLED = FALSE
		OFF[VIRTUAL,POWER_FB]
	    }
	    ACTIVE(FIND_STRING(DATA.TEXT,'Copyright (c) 2005 - 2010 RGB Spectrum',1)):	//NOW THAT IT HAS BOOTED WE CAN BEGIN POLING IT
	    {
		nOUTPUT_ENABLED = TRUE
		ON[VIRTUAL,POWER_FB]
	    }
	}
    }
}
TIMELINE_EVENT[tlDEV_POLL]
{
    SWITCH(TIMELINE.SEQUENCE)
    {
	CASE 1:
	{
	    IF(nOUTPUT_ENABLED)
	    {
		SEND_STRING REAL,"'status',$0D"				//POLL THE LAMP
		nDEV_CMDS_MISSED++					//INCREMENTS SO THAR WE CAN TRACKS HOW MANY TIMES WE HAVE POLLED IF THE PROJ BECOMES DISCONECTED
		IF(nDEV_CMDS_MISSED >7)					//PROJECTOR HAS BEEN OFFLINE FOR A WHILE
		{
		    OFF[VIRTUAL,251]					//PROJECTOR IS IN TIME OUT... IT HAS BEEN VERY BAD
		}
	    }
	}
    }
}

CHANNEL_EVENT[VIRTUAL,nBUTTON_CHANNELS]						//PRESET RECALLS
{
    ON:
    {
	nLAST_VIEW = GET_LAST(nBUTTON_CHANNELS)
	WAIT_UNTIL(nOUTPUT_ENABLED)
	{
	    SEND_STRING REAL,"'Wpload ',ITOA(nLAST_VIEW),' 1',$0D"	//RECALL TEH PRESET
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
