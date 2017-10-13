MODULE_NAME='Tesira Level Control'(DEV Virtual,DEV Real, Char ID_TAG[60], INTEGER Index)
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
DEFINE_DEVICE
#if_defined 'SO AUTOCOMPLETE'		//THIS WILL NEVER BE DEFINED
Virtual		=	33001:1:0
Real		=	5001:1:0
#end_if
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

//TIMELINES
tlVOL_UP		=	2
tlVOL_DOWN		=	3
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
#IF_DEFINED 'SUCH DEFINE'
VOLATILE CHAR ID_Tag[60]
VOLATILE INTEGER Index
#END_IF

VOLATILE INTEGER nVOLUME_LEVEL

//TIMLINE VARS
VOLATILE LONG lRAMP_TIMES[] = {150}				//TIME LIST FOR THE VOLUME RAMP TIMELINE
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

DATA_EVENT[Virtual]
{
    COMMAND:
    {
	IF(FIND_STRING(DATA.TEXT,'REG',1))
	{
	    SEND_COMMAND Virtual,"'+REG,FDRLVL,',ID_Tag,',',ITOA(Index)"
	}
    }
}


//VOLUME CONTROL AND MUTE
LEVEL_EVENT[VIRTUAL,1]							//THE USER ADJUSTABLE VOLUME LEVEL
{
    LOCAL_VAR SINTEGER sTEMP_VOL
    
    nVOLUME_LEVEL = LEVEL.VALUE						
    sTEMP_VOL = TYPE_CAST(nVOLUME_LEVEL/2.55)-90			//MAKE IT A -90 THROUGH 10 RANGE
    SEND_STRING Real,"ID_Tag,' set level ',ITOA(Index),' ',FTOA(sTEMP_VOL),$0A,$0D"

}

CHANNEL_EVENT[VIRTUAL,24]							//VOL UP
{
    ON:
    {
	IF(nVOLUME_LEVEL<245)
	{
	    nVOLUME_LEVEL = nVOLUME_LEVEL+10
	    SEND_LEVEL VIRTUAL,1,nVOLUME_LEVEL
	}
	WAIT 10 'VOLUPDDL'
	{
	    TIMELINE_CREATE(tlVOL_UP,lRAMP_TIMES,LENGTH_ARRAY(lRAMP_TIMES),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
    }
    OFF:
    {
	CANCEL_WAIT 'VOLUPDDL'
	WAIT 1 TIMELINE_KILL(tlVOL_UP)
    }
}

TIMELINE_EVENT[tlVOL_UP]							//HOLD VOLUME UP RAMPING
{
	IF(nVOLUME_LEVEL<250)
	{
	    nVOLUME_LEVEL = nVOLUME_LEVEL+5
	    SEND_LEVEL VIRTUAL,1,nVOLUME_LEVEL
	}
}

CHANNEL_EVENT[VIRTUAL,25]							//VOL DOWN
{
    ON:
    {
	IF(nVOLUME_LEVEL>10)
	{
	    nVOLUME_LEVEL = nVOLUME_LEVEL-10
	    SEND_LEVEL VIRTUAL,1,nVOLUME_LEVEL
	}
	WAIT 10 'VOLDOWNDDL'
	{
	    TIMELINE_CREATE(tlVOL_DOWN,lRAMP_TIMES,LENGTH_ARRAY(lRAMP_TIMES),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
    }
    OFF:
    {
	CANCEL_WAIT 'VOLDOWNDDL'
	WAIT 1 TIMELINE_KILL(tlVOL_DOWN)
    }
}

TIMELINE_EVENT[tlVOL_DOWN]							//HOLD VOLUME DOWN RAMPING
{
	IF(nVOLUME_LEVEL>5)
	{
	    nVOLUME_LEVEL = nVOLUME_LEVEL-5
	    SEND_LEVEL VIRTUAL,1,nVOLUME_LEVEL
	}
}


CHANNEL_EVENT[VIRTUAL,26]							//VOLUME MUTE
{
    ON:
    {
	[VIRTUAL,199] = ![VIRTUAL,199]						//TOGGLE THE MUTE
    }
}

CHANNEL_EVENT[VIRTUAL,199]
{
    ON:
    {
	SEND_STRING Real,"ID_Tag,' set mute ',ITOA(Index),' 1',$0A,$0D"	//SEND THE MUTE
    }
    OFF:
    {
	SEND_STRING Real,"ID_Tag,' set mute ',ITOA(Index),' 0',$0A,$0D"	//SEND THE MUTE
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
