MODULE_NAME='BlackmagicVideoHub'(DEV VIRTUAL,DEV REAL)
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

#IF_DEFINED 'DEFDEVS'
VIRTUAL		=	33001:1:0
REAL		=	5001:1:0
#END_IF

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

VOLATILE INTEGER bNOTIFICATIONS_ENABLED					//TRACKS WEATHER WE HAVE SENT THE ENABLE NOTIFICATIONS STRING THIS GO ARROUND

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


#INCLUDE 'SNAPI'
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[REAL]
{
    ONLINE:
    {
	SEND_COMMAND DATA.DEVICE,'SET BAUD 9600,N,8,1 485 DISABLE'		//YES WE ARE USING RS422 FOR THIS ONE!!!
	WAIT 4 SEND_STRING DATA.DEVICE,"$0D"					//SEND A CR TO GET A '>' AS A RESPONSE
	ON[VIRTUAL,DATA_INITIALIZED]						//THE DATA IS SOMETHING SOMETHING IZED
    }
    STRING:
    {
	LOCAL_VAR CHAR cDEV_BUFFER[250]						//STORES THE INCOMMING STRING IN A BUFFER FOR PROCESSING
	LOCAL_VAR CHAR cINPUT[4]						//STORES THE FIRST HALF OF A PARCED SWITCH STRING
	LOCAL_VAR CHAR cOUTPUT[4]						//STORES THE SECOND HALF OF A PARCED STRING
	LOCAL_VAR INTEGER nINPUT						//DECIMAL INPUT NUMBER
	LOCAL_VAR INTEGER nOUTPUT						//DECIMAL OUTPUT NUMBER
	cDEV_BUFFER = "cDEV_BUFFER,DATA.TEXT"					//STORES THE INCOMING STRING INTHE BUFFER
	
	ON[VIRTUAL,DEVICE_COMMUNICATING]
	CANCEL_WAIT 'COMTIMEOUT'
	WAIT 600 'COMTIMEOUT'							//IF WE HAVENT RECIEVED SOMETHIGN IN 1 WE HAVE LOST CONNECTION (THE UNIT SENDS OUT A '>' HEART BEAT EVERY 30 SECONDS
	{
	    OFF[VIRTUAL,DEVICE_COMMUNICATING]
	}
	
	SELECT
	{
	    ACTIVE(FIND_STRING(cDEV_BUFFER,'>',1) || FIND_STRING(cDEV_BUFFER,$0D,1))://IF WE GET A CR OR > CLEAR THE BUFFER
	    {
		CLEAR_BUFFER cDEV_BUFFER
		IF(bNOTIFICATIONS_ENABLED == FALSE)		//IF WE HAVENT ENABLED NOTIFICATIONS ALREADY, DO IT
		{
		    SEND_STRING REAL,"'@ ?',$0D"
		    bNOTIFICATIONS_ENABLED = TRUE		//NOTIFICATIONS ARE NOW ENABLEDED FOR THIS BOOT
		}
	    }
	    ACTIVE(LENGTH_STRING(cDEV_BUFFER)>100):				//IF THERE IS BUILTUP CRAP, REMOVE IT
	    {
		CLEAR_BUFFER cDEV_BUFFER
	    }
	}
    }
}

DATA_EVENT[VIRTUAL]
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
	    
	    nINPUT = ATOI(cTEMP1)				//IT MAY SEEM POINTLESS BUT CONVERTING TO AN INT HELPS ENSURE THAT WE ARE ONLY SENDING A VALID NUMBER
	    nOUTPUT = ATOI(cTEMP2)
	    
	    SEND_STRING REAL,"$40,$20,$58,$3A,$30,$2F,ITOHEX(nOUTPUT-1),',',ITOHEX(nINPUT-1),$0D,$0A"
	}
    }
}
//

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
