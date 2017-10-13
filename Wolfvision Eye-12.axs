MODULE_NAME='Wolfvision Eye-12'(DEV VIRTUAL, DEV REAL)
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
#DEFINE LISTVARS
#IF_NOT_DEFINED LISTVARS					//just there to allow auto complete
VIRTUAL		=	33001:1:0
REAL		=	5001:1:0
#END_IF
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
//SNAPI CONSTANTS
// Document Camera Channels
POWER                  = 9     // Momentary: Cycle power
PWR_ON                 = 27    // Momentary: Set power on
PWR_OFF                = 28    // Momentary: Set power off
ZOOM_OUT               = 158   // Ramping:   Ramp zoom out
ZOOM_OUT_FB            = 158   // Feedback:  Ramp zoom out feedback
ZOOM_IN                = 159   // Ramping:   Ramp zoom in
ZOOM_IN_FB             = 159   // Feedback:  Ramp zoom in feedback
FOCUS_NEAR             = 160   // Ramping:   Ramp focus near
FOCUS_NEAR_FB          = 160   // Feedback:  Ramp focus near feedback
FOCUS_FAR              = 161   // Ramping:   Ramp focus far
FOCUS_FAR_FB           = 161   // Feedback:  Focus ramp far feedback
AUTO_FOCUS_ON          = 162   // Discrete:  Set auto focus on or off
AUTO_FOCUS_FB          = 162   // Feedback:  Auto focus feedback
AUTO_IRIS_ON           = 163   // Discrete:  Set auto iris on or off
AUTO_IRIS_FB           = 163   // Feedback:  Auto iris feedback
AUTO_FOCUS             = 172   // Momentary: Cycle auto focus
AUTO_IRIS              = 173   // Momentary: Cycle auto iris
IRIS_OPEN              = 174   // Ramping:   Ramp iris open
IRIS_OPEN_FB           = 174   // Feedback:  Ramp iris open feedback
IRIS_CLOSE             = 175   // Ramping:   Ramp iris closed
IRIS_CLOSE_FB          = 175   // Feedback:  Ramp iris closed feedback
DEVICE_COMMUNICATING   = 251   // Feedback:  Device online event
DATA_INITIALIZED       = 252   // Feedback:  Data initialized event
POWER_ON               = 255   // Discrete:  Set power
POWER_FB               = 255   // Feedback:  Power feedback


//TIMELINES
tlCAM_POLL		= 1	//USED TO POLL THE CAMERA
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

//TIMELINE VARS
VOLATILE LONG lPOLL_TIMES[]	=	{10000}			//30 SECOND POWER POLL TIME

//DEVICE VARS
VOLATILE INTEGER nCOMMANDS_MISSED		//NUMBERS OF STRINGS THAT HAVE BEEN MISSED
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

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
//COMS STUFF
DATA_EVENT[REAL]
{
    ONLINE:
    {
	SEND_COMMAND REAL,'SET BAUD 115200 N,8,1'
	TIMELINE_CREATE(tlCAM_POLL,lPOLL_TIMES,LENGTH_ARRAY(lPOLL_TIMES),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	ON[VIRTUAL,DATA_INITIALIZED]
    }
    STRING:
    {
	nCOMMANDS_MISSED = 0					//WE ARE OBVIOUSILY TALKING
	ON[VIRTUAL,DEVICE_COMMUNICATING]
    }
}

TIMELINE_EVENT[tlCAM_POLL]
{
    IF(nCOMMANDS_MISSED >2)
    {
	OFF[DEVICE_COMMUNICATING]
    }
    SEND_STRING REAL,"$00,$30,$00"
    nCOMMANDS_MISSED++
}


//POWER STUFF
CHANNEL_EVENT[VIRTUAL,POWER]
{
    ON:
    {
	[VIRTUAL,POWER_FB] = ![VIRTUAL,POWER_FB] 
    }
}
CHANNEL_EVENT[VIRTUAL,PWR_ON]
{
    ON:
    {
	ON[VIRTUAL,POWER_FB]
    }
}
CHANNEL_EVENT[VIRTUAL,PWR_OFF]
{
    ON:
    {
	OFF[VIRTUAL,POWER_FB]
    }
}
CHANNEL_EVENT[VIRTUAL,POWER_FB]
{
    ON:
    {
	SEND_STRING REAL,"$01,$30,$01,$01"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$30,$01,$00"
    }
}

CHANNEL_EVENT[VIRTUAL,ZOOM_IN]
{
    ON:
    {
	SEND_STRING REAL,"$01,$20,$01,$12"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$2F,$01,$00"
    }
}
CHANNEL_EVENT[VIRTUAL,ZOOM_OUT]
{
    ON:
    {
	SEND_STRING REAL,"$01,$20,$01,$11"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$2F,$01,$00"
    }
}

CHANNEL_EVENT[VIRTUAL,AUTO_FOCUS_ON]
{
    ON:
    {
	SEND_STRING REAL,"$01,$31,$01,$01"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$31,$01,$00"
    }
}
CHANNEL_EVENT[VIRTUAL,AUTO_FOCUS]
{
    ON:
    {
	[VIRTUAL,AUTO_FOCUS_ON] = ![VIRTUAL,AUTO_FOCUS_ON]
    }
}
CHANNEL_EVENT[VIRTUAL,FOCUS_NEAR]
{
    ON:
    {
	IF([VIRTUAL,AUTO_FOCUS_ON])
	{
	    OFF[VIRTUAL,AUTO_FOCUS_ON]
	}
	SEND_STRING REAL,"$01,$21,$01,$12"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$2F,$01,$00"
    }
}
CHANNEL_EVENT[VIRTUAL,FOCUS_FAR]
{
    ON:
    {
	IF([VIRTUAL,AUTO_FOCUS_ON])
	{
	    OFF[VIRTUAL,AUTO_FOCUS_ON]
	}
	SEND_STRING REAL,"$01,$21,$01,$11"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$2F,$01,$00"
    }
}
CHANNEL_EVENT[VIRTUAL,AUTO_IRIS_ON]
{
    ON:
    {
	SEND_STRING REAL,"$01,$32,$01,$01"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$32,$01,$00"
    }
}
CHANNEL_EVENT[VIRTUAL,AUTO_IRIS]
{
    ON:
    {
	[VIRTUAL,AUTO_IRIS_ON] = ![VIRTUAL,AUTO_IRIS_ON]
    }
}
CHANNEL_EVENT[VIRTUAL,IRIS_CLOSE]
{
    ON:
    {
	IF([VIRTUAL,AUTO_IRIS_ON])
	{
	    OFF[VIRTUAL,AUTO_IRIS_ON]
	}
	SEND_STRING REAL,"$01,$22,$01,$12"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$2F,$01,$00"
    }
}
CHANNEL_EVENT[VIRTUAL,IRIS_OPEN]
{
    ON:
    {
	IF([VIRTUAL,AUTO_IRIS_ON])
	{
	    OFF[VIRTUAL,AUTO_IRIS_ON]
	}
	SEND_STRING REAL,"$01,$22,$01,$11"
    }
    OFF:
    {
	SEND_STRING REAL,"$01,$2F,$01,$00"
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
