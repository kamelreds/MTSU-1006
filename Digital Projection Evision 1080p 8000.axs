MODULE_NAME='Digital Projection Evision 1080p 8000'(DEV VIRTUAL, DEV REAL)
(***********************************************************)
(*  FILE CREATED ON: 11/29/2012  AT: 15:09:28              *)
(***********************************************************)
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 01/30/2013  AT: 13:53:23        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*

*)    
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

#IF_DEFINED 'LOLWUT'						//THIS WILL NEVER BE DEFINED... IT IS JUST FOR AUTOCOMPLETE
Real		=	5001:1:0
VIRTUAL		=	33001:1:0
#END_IF

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

SOURCE_NUMBERS[][1]	= {'1','2','3','4','5','6'}
SOURCE_NAMES[][20]	= {'HDMI','DVI','VGA','BNC','Composite','S-Video','3G SDI'}

//TIMELINES
tlPROJ_POLL		=	1			//TIMELINE TO POLL THE PROJ

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

VOLATILE INTEGER nPROJ_POWER						//DEVICE LEVEL POWER FEEDBACK FRO THE PROJ
VOLATILE INTEGER nPROJ_LAMP						//DEVICE LEVEL LAMP HOUR FEEDBACK FOR THE PROJ

VOLATILE INTEGER nPROJ_CMDS_MISSED					//TRACKS THE NUMBER OF FAILED COMMANDS
VOLATILE INTEGER bPROJ_ERROR_SET					//GOES HIGH IF THE PROJ CAUSED A STOP ERROR

VOLATILE INTEGER SOURCE_CHANNELS[]	= {31,32,33,34,35,36}
//TIMELINE VARS
VOLATILE LONG lPROJ_POLL_TIMES[] = {15000,500,500}			//15 SECONDS FOR LAMP POLL THEN .5 SECONDS FOR POWER POLL
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE
([VIRTUAL,31]..[VIRTUAL,36])

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
// {{NSX_DEFINE_EVENT
// VIRTUAL DEVICE
DATA_EVENT[VIRTUAL]
{
    COMMAND:
    {
    STACK_VAR CHAR cINPUT_BUFFER[250]							//STORES THE COMMAND FOR PROCESSING
    STACK_VAR INTEGER nDATA_INT								//USED TO STORE THE PARCED OUT INT
    
    cINPUT_BUFFER = DATA.TEXT
    
    SELECT
    {
	ACTIVE(FIND_STRING(cINPUT_BUFFER,'INPUTSELECT-',1)):
	{
	    REMOVE_STRING(cINPUT_BUFFER,'INPUTSELECT-',1)
	    nDATA_INT = ATOI(cINPUT_BUFFER)
	    ON[VIRTUAL,SOURCE_CHANNELS[nDATA_INT]]
	}
    }
  }
}

CHANNEL_EVENT[VIRTUAL,SOURCE_CHANNELS]
{
    ON:
    {
	SEND_STRING Real,"'op input.sel = ',ITOA(SOURCE_NUMBERS[GET_LAST(SOURCE_CHANNELS)]),$0D"
	SEND_COMMAND VIRTUAL,"'INPUT-',SOURCE_NAMES[GET_LAST(SOURCE_CHANNELS)],$0D"
    }
}

// REAL DEVICE
DATA_EVENT[REAL]
{
    ONLINE:
    {
	SEND_COMMAND DATA.DEVICE,"'SET BAUD 38400,N,8,1'"
	TIMELINE_CREATE(tlPROJ_POLL,lPROJ_POLL_TIMES,LENGTH_ARRAY(lPROJ_POLL_TIMES),TIMELINE_RELATIVE,TIMELINE_REPEAT)	//START POLLING THE PROJ
    }
    STRING:
    {
	LOCAL_VAR CHAR cPROJ_BUFFER[250]
	LOCAL_VAR INTEGER nPROJ_TEMP						//THROWAWAY INT USED FOR PROJ STATE CHANGE DETECTION
	
	cPROJ_BUFFER = "cPROJ_BUFFER,DATA.TEXT"					//STORE THE INCOMING STRING
	nPROJ_CMDS_MISSED = 0							//THE PROJ IS CONNECTED SO ZERO THE MISSED CMDS COUNTER
	ON[VIRTUAL,252]								//SET THE RMS DEVICE ONLINE FLAG
	ON[VIRTUAL,251]
	
	REMOVE_STRING(cPROJ_BUFFER,"$0D,$0D,$0A",1)				//REMOVE THE ECHO FROM THE STRING
	
	SELECT
	{
	    ACTIVE(FIND_STRING(cPROJ_BUFFER,'LAMP1.HOURS = ',1)):		//INCOMING LAMP HOURS
	    {
		REMOVE_STRING(cPROJ_BUFFER,' = ',1)				//STRIP THE HEADER
		nPROJ_TEMP = ATOI(cPROJ_BUFFER)					//PARCE THE DATA
		
		SEND_COMMAND VIRTUAL,"'LAMPTIME-',ITOA(nPROJ_TEMP)"		//SEND THE NEW LAMP DATA
		
		CLEAR_BUFFER cPROJ_BUFFER
	    }
	    ACTIVE(FIND_STRING(cPROJ_BUFFER,'LAMP2.HOURS = ',1)):		//INCOMING LAMP HOURS
	    {
		REMOVE_STRING(cPROJ_BUFFER,' = ',1)				//STRIP THE HEADER
		nPROJ_TEMP = ATOI(cPROJ_BUFFER)					//PARCE THE DATA
		
		SEND_COMMAND VIRTUAL,"'LAMPTIME2-',ITOA(nPROJ_TEMP)"		//SEND THE NEW LAMP DATA
		
		CLEAR_BUFFER cPROJ_BUFFER
	    }
	    ACTIVE(FIND_STRING(cPROJ_BUFFER,'INPUT.SEL = ',1)):			//INCOMING LAMP HOURS
	    {
		REMOVE_STRING(cPROJ_BUFFER,' = ',1)				//STRIP THE HEADER
		nPROJ_TEMP = ATOI(cPROJ_BUFFER)					//PARCE THE DATA
		
		ON[VIRTUAL,SOURCE_CHANNELS[nPROJ_TEMP]]				//UPDATE THE INPUT FB
		
		CLEAR_BUFFER cPROJ_BUFFER
	    }
	    ACTIVE(FIND_STRING(cPROJ_BUFFER,'STATUS =',1)):			//INCOMING POWER FB
	    {
		REMOVE_STRING(cPROJ_BUFFER,' = ',1)				//STRIP THE HEADER
		nPROJ_TEMP = ATOI(cPROJ_BUFFER)					//PARCE THE DATA
		
		IF(nPROJ_TEMP != 4 && bPROJ_ERROR_SET == 1)			//CHECK FOR ERROR RECOVERY
		{
		    bPROJ_ERROR_SET = 0
		    ON[VIRTUAL,251]						//AAAAAND WERE BACK!
		}
		
		SWITCH(nPROJ_TEMP)
		{
		    CASE 0:
		    {
			OFF[VIRTUAL,LAMP_POWER_FB]
			OFF[VIRTUAL,LAMP_WARMING_FB]
			OFF[VIRTUAL,LAMP_COOLING_FB]
		    }
		    CASE 1:
		    {
			ON[VIRTUAL,LAMP_WARMING_FB]
		    }
		    CASE 2:
		    {
			ON[VIRTUAL,LAMP_POWER_FB]
			OFF[VIRTUAL,LAMP_WARMING_FB]
			OFF[VIRTUAL,LAMP_COOLING_FB]
		    }
		    CASE 3:
		    {
			ON[VIRTUAL,LAMP_COOLING_FB]
		    }
		    CASE 4:
		    {
			OFF[VIRTUAL,DEVICE_COMMUNICATING]				//THIS IS FOR AN ERROR CONDITION
			bPROJ_ERROR_SET = 1						//PROJ JUST TRIGGERED A STOP ERROR
			SEND_COMMAND VIRTUAL,"'DEBUG-1'"				//SEND THE ERROR FLAG TO RMS
		    }
		}
		
		CLEAR_BUFFER cPROJ_BUFFER
	    }    
	    ACTIVE(FIND_STRING(cPROJ_BUFFER,$0D,1)):				//IF A CR COMES IN AND NOTHIGN ELSE HAS TRIGGED CLEAR THE BUFFER
	    {
		CLEAR_BUFFER cPROJ_BUFFER
	    }
	    ACTIVE(LENGTH_STRING(cPROJ_BUFFER)>100):				//IF THE STRING GETS TOO LONG KILL IT
	    {
		CLEAR_BUFFER cPROJ_BUFFER
	    }
	}
    }
}

//TIMELINES
TIMELINE_EVENT[tlPROJ_POLL]
{
    SWITCH(TIMELINE.SEQUENCE)
    {
	CASE 1:
	{
	    SEND_STRING REAL,"'op lamp1.hours ?',$0D"			//POLL THE LAMP
	    nPROJ_CMDS_MISSED++						//INCREMENTS SO THAR WE CAN TRACKS HOW MANY TIMES WE HAVE POLLED IF THE PROJ BECOMES DISCONECTED
	    IF(nPROJ_CMDS_MISSED >7)					//PROJECTOR HAS BEEN OFFLINE FOR A WHILE
	    {
		bPROJ_ERROR_SET = 1					//PROJ HAS TRIGGERED A STOP ERROR
		OFF[VIRTUAL,251]					//PROJECTOR IS IN TIME OUT... IT HAS BEEN VERY BAD
	    }
	}
	CASE 2:
	{
	    SEND_STRING REAL,"'op lamp2.hours ?',$0D"			//POLL THE LAMP
	}
	CASE 3:
	{
	    SEND_STRING REAL,"'op status ?',$0D"			//POLL FOR POWER
	}
	CASE 4:
	{
	    SEND_STRING REAL,"'op input.sel ?',$0D"			//POLL FOR POWER
	}
    }
}

//PIC MUTE
CHANNEL_EVENT[VIRTUAL,PIC_MUTE]						//MANAGE THE TOGGLE FOR THE PIC MUTE
{
    ON:
    {
	[VIRTUAL,PIC_MUTE_ON] = ![VIRTUAL,PIC_MUTE_ON]
    }
}
CHANNEL_EVENT[VIRTUAL,PIC_MUTE_ON]
{
    ON:
    {
	SEND_STRING Real,"'op picture.mute =1',$0D"				//CLOSE THE SHUTTER
    }
    OFF:
    {
	SEND_STRING Real,"'op picture.mute =0',$0D"				//OPEN THE SHUTTER
    }
}



// VIRTUAL POWER ON CHANNELS
CHANNEL_EVENT[VIRTUAL,27]
CHANNEL_EVENT[VIRTUAL,28]
{
    ON:
    {
	STACK_VAR INTEGER nChIdx
	nChIdx = CHANNEL.CHANNEL-27+1
	SWITCH(nChIdx)
	{
	    CASE  1:	//POWER ON
	    {
		SEND_STRING REAL,"'op power.on',$0D"
	    }	
	    CASE  2:	//POWER OFF
	    {
		SEND_STRING REAL,"'op power.off',$0D"
	    }
	}
    }
}


// }}NSX_DEFINE_EVENT



(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
