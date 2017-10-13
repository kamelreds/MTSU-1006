MODULE_NAME='IPBlackmagicVideoHub'(DEV REAL, DEV VIRTUAL, CHAR IP[16], INTEGER PORT)
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

#IF_DEFINED 'WOW SUCH DEFINE'
REAL	= 0:3:0
VIRTUAL = 33001:1:0
#END_IF

dvMASTER	=	0:1:0		//THE MASTER WILL ALWAYS BE THE SAME
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
#IF_DEFINED 'WOW SUCH DEFINE'
VOLATILE CHAR IP[16]
VOLATILE INTEGER PORT
#END_IF

VOLATILE INTEGER bIS_CONNECTED
VOLATILE CHAR cERRORS[250]
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
#INCLUDE'SNAPI'
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[VIRTUAL]						//INCOMING SWITCH
{
    COMMAND:
    {
	LOCAL_VAR CHAR cDATA_BUFFER[50]
	LOCAL_VAR CHAR cTEMP1[10]
	LOCAL_VAR CHAR cTEMP2[10]
	LOCAL_VAR INTEGER nINPUT
	LOCAL_VAR INTEGER nOUTPUT
	cDATA_BUFFER =DATA.TEXT
	cDATA_BUFFER = UPPER_STRING(cDATA_BUFFER)		//MAKES EVERYTHING UPPER CASE, BECASUSE USERS
	
	IF(FIND_STRING(cDATA_BUFFER,'CL',1))			//THERE IS A UNWANTED LEVEL VAR HERE THAT WE WILL REMOVE
	{
	    REMOVE_STRING(cDATA_BUFFER,'I',1)
	    cDATA_BUFFER = "'CI',cDATA_BUFFER"			//MAKE IT AN CI#O#T STYLE STRING
	}
	IF(FIND_STRING(cDATA_BUFFER,'CI',1))			//LOOK FOR A PROPERILY FORMATED STRING
	{
	    REMOVE_STRING(cDATA_BUFFER,'CI',1)
	    cTEMP1 = REMOVE_STRING(cDATA_BUFFER,'O',1)
	    cTEMP2 = REMOVE_STRING(cDATA_BUFFER,'T',1)
	    
	    nINPUT = ATOI(cTEMP1) -1				//POS BLACKMAGIC USED 0-15 FOR PORTS NUMBERED 1-16
	    nOUTPUT = ATOI(cTEMP2) -1
	    
	    SEND_STRING REAL,"'VIDEO OUTPUT ROUTING',$3A,$0D,$0A,ITOA(nOUTPUT),$20,ITOA(nINPUT),$0D,$0A,$0D,$0A"
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
