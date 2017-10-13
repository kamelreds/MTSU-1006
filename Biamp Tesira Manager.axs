MODULE_NAME='Biamp Tesira Manager'(DEV Virtual, DEV Real)
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
Virtual		=	33001:1:0
REAL		=	5001:1:0
#END_IF

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
//TIMELINES
tlDEV_POLL		=	1			//TIMELINE TO POLL THE DEVICE
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
VOLATILE INTEGER nCOMMANDS_MISSED				//TRACKS OFFLINE STATUS
VOLATILE LONG lDEV_POLL_TIMES[] = {15000}			//15 SECONDS FOR ONLINE POLL
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

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
	SEND_COMMAND DATA.DEVICE,"'SET BAUD 38400 N,8,1 485 DISABLE'"
	TIMELINE_CREATE(tlDEV_POLL,lDEV_POLL_TIMES,LENGTH_ARRAY(lDEV_POLL_TIMES),TIMELINE_RELATIVE,TIMELINE_REPEAT)	//START POLLING THE PROJ
	ON[VIRTUAL,DATA_INITIALIZED]
    }
    STRING:
    {
	ON[VIRTUAL,DEVICE_COMMUNICATING]
	nCOMMANDS_MISSED = 0						//THE DEVICE IS RESPONDING
    }
}

//TIMELINES
TIMELINE_EVENT[tlDEV_POLL]
{
    SEND_STRING REAL,"'DEVICE get serialNumber',$0A,$0D"		//POLL POWER
    nCOMMANDS_MISSED++							//INCREMENTS SO THAR WE CAN TRACKS HOW MANY TIMES WE HAVE POLLED IF THE PROJ BECOMES DISCONECTED
    IF(nCOMMANDS_MISSED >7)						//DSP HAS BEEN OFFLINE FOR A WHILE
    {
	OFF[VIRTUAL,251]						//DSP IS IN TIME OUT... IT HAS BEEN VERY BAD
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
