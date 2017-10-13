//*********************************************************************
//
//             AMX Resource Management Suite  (4.1.13)
//
//*********************************************************************
/*
 *  Legal Notice :
 *
 *     Copyright, AMX LLC, 2011
 *
 *     Private, proprietary information, the sole property of AMX LLC.  The
 *     contents, ideas, and concepts expressed herein are not to be disclosed
 *     except within the confines of a confidential relationship and only
 *     then on a need to know basis.
 *
 *     Any entity in possession of this AMX Software shall not, and shall not
 *     permit any other person to, disclose, display, loan, publish, transfer
 *     (whether by sale, assignment, exchange, gift, operation of law or
 *     otherwise), license, sublicense, copy, or otherwise disseminate this
 *     AMX Software.
 *
 *     This AMX Software is owned by AMX and is protected by United States
 *     copyright laws, patent laws, international treaty provisions, and/or
 *     state of Texas trade secret laws.
 *
 *     Portions of this AMX Software may, from time to time, include
 *     pre-release code and such code may not be at the level of performance,
 *     compatibility and functionality of the final code. The pre-release code
 *     may not operate correctly and may be substantially modified prior to
 *     final release or certain features may not be generally released. AMX is
 *     not obligated to make or support any pre-release code. All pre-release
 *     code is provided "as is" with no warranties.
 *
 *     This AMX Software is provided with restricted rights. Use, duplication,
 *     or disclosure by the Government is subject to restrictions as set forth
 *     in subparagraph (1)(ii) of The Rights in Technical Data and Computer
 *     Software clause at DFARS 252.227-7013 or subparagraphs (1) and (2) of
 *     the Commercial Computer Software Restricted Rights at 48 CFR 52.227-19,
 *     as applicable.
*/
MODULE_NAME='RmsTouchPanelMonitor'(DEV vdvRMS,
                                   DEV dvMonitoredDevice)

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This NetLinx module contains the source code for       *)
(*  monitoring and controlling a touch panel device        *)
(*  in RMS.                                                *)
(*                                                         *)
(*  This module wil register a base set of asset           *)
(*  monitoring parameters, metadata properties, and        *)
(*  contorl methods.  It will update the monitored         *)
(*  parameters as chagnes from the touch panel are         *)
(*  detected.                                              *)
(*                                                         *)
(*  This module will attempt to provide more information   *)
(*  to RMS for wireless panels.  These panels are          *)
(*  determined by their DEVICE_ID.                         *)
(*                                                         *)
(***********************************************************)

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

CHAR MONITOR_NAME[]       = 'RMS Touch Panel Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'RmsTouchPanelMon';
CHAR MONITOR_VERSION[]    = '4.1.13';
CHAR MONITOR_ASSET_TYPE[] = 'TouchPanel';
CHAR MONITOR_ASSET_NAME[] = ''; // populate this property to override the asset name
                                // leave it empty to auto-populate the device name

// this constant should be set to the defined level
// configured in the touch panel file for monitoring
// the battery level.  The default level RMS defines is
// level 8.
INTEGER TP_LEVEL_BATTERY  = 8


// this constant should be set to the defined channel
// configured in the touch panel file for monitoring
// docking state.  The default channel RMS defines is
// channel 255.
INTEGER TP_CHANNEL_DOCKED = 255


// Include a listing of all portable touch panel device IDs
//    MVP-7500  = 0x0120 <288>
//    MVP-7500  = 0x013A <314>
//    MVP-8400  = 0x013B <315>
//    MVP-8400  = 0x0121 <289>
//    MVP-8400i = 0x0143 <323>
//    MVP-8400i (reduced) = 0x0148 <328>
//    MVP-5200i = 0x0149 <329>
//    MVP-5000  = 0x014C <332>
//    MVP-5100  = 0x014D <333>
//    MVP-9000  = 0x0157 <343>
INTEGER DEVICE_ID_LIST_PORTABLE_PANEL[] = { 288,314,315,289,323,328,329,332,333,343 }


// Include a listing of all headless touch panel device IDs
//    NXV-300 = 0x155 <341>
INTEGER DEVICE_ID_LIST_HEADLESS_PANEL[] = { 341 }


// Define a minimum delta change threshold for the battery
// level so that the parameter updates sent to the RMS server
// are only sent when the battery level meets or exceeds the
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changed in the battery level.
INTEGER RMS_BATTERY_MINIMUM_CHANGE_THRESHOLD = 3;

// Define the default low battery threshold percentage value (0-100)
INTEGER RMS_TP_LOW_BATTERY_THRESHOLD = 5;

// Define the default low battery threshold delay in minutes
INTEGER RMS_TP_LOW_BATTERY_DELAY = 5;

// Define a minimum delta change threshold for the wireless
// signal strength level so that the parameter updates sent
// to the RMS server are only sent when the signal strength
// level meets or exceeds the this threshold.  This will
// prevent excessive parameter updates from being sent to
// RMS for minor fluxuating changes in the signal strength.
INTEGER RMS_WIRELESS_SIGNAL_STRENGTH_MINIMUM_CHANGE_THRESHOLD = 5;


// RMS Touch Panel Monitoring Timeline
INTEGER TL_MONITOR = 1;
LONG    PanelMonitoringTimeArray[1] = {30000};


// include RMS MONITOR COMMON AXI
#INCLUDE 'RmsMonitorCommon';


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

STRUCTURE RmsTouchPanelInfo
{
  // variables for touch panel capabilities
  CHAR isG4Panel;
  CHAR isHeadlessPanel;
  CHAR isPortablePanel;
  CHAR hasWireless;
  CHAR hasBattery;
  CHAR hasDock;
  CHAR hasCustomEventSupport

  // variables for monitored parameters & metadata properties
  CHAR docked;
  INTEGER displayTimeout;
  INTEGER shutdownTimeout;
  INTEGER wirelessChannel;
  SLONG wirelessSignalStrength;
  CHAR wirelessWapMacAddress[50];
  CHAR wirelessSSID[50];
  CHAR macAddress[100];
  INTEGER batteryLevel;
  CHAR batteryBaseVersion[100];
  INTEGER volumeLevel;
  CHAR volumeMute;
  INTEGER brightnessLevel;
  CHAR charging;
  CHAR fileSystem[50];
  CHAR memory[50];
  CHAR startTime[30];
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

// RMS Touch Panel Monitoring Variable
RmsTouchPanelInfo panelInfo;

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)


(***********************************************************)
(* Name:  RegisterAsset                                    *)
(* Args:  RmsAsset asset data object to be registered .    *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset.                             *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAsset(RmsAsset asset)
{
  // setup any optional asset properties here
  //asset.name        = 'My Touch Panel';

  IF(panelInfo.isG4Panel)
  {
    asset.description = 'AMX G4 Touch Panel User Interface';
  }
  ELSE IF(panelInfo.isHeadlessPanel)
  {
    asset.description = 'AMX Headless Touch Panel User Interface';
  }
  ELSE
  {
    asset.description = 'AMX Touch Panel User Interface';
  }

  // perform registration of this
  // AMX Device as a RMS Asset
  //
  // (registering this asset as an 'AMX' asset
  //  will pre-populate all available asset
  //  data fields with information obtained
  //  from a NetLinx DeviceInfo query.)
  RmsAssetRegisterAmxDevice(dvMonitoredDevice, asset);
}


(***********************************************************)
(* Name:  RegisterAssetParameters                          *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's parameters to be monitored *)
(*        by RMS.                                          *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetParameters()
{
  STACK_VAR RmsAssetParameterThreshold threshold;

  // register all asset monitoring parameters now.

  // register the default "Device Online" parameter
  RmsAssetOnlineParameterEnqueue (assetClientKey, DEVICE_ID(dvMonitoredDevice));

  // register asset power
  RmsAssetPowerParameterEnqueue(assetClientKey,DEVICE_ID(dvMonitoredDevice));

  // if this panel supports the Gibraltar firmware (CUSTOM_EVENTS), then register these additional monitored parameters
  IF(panelInfo.hasCustomEventSupport)
  {
      // brightness level
      RmsAssetParameterEnqueueLevel(assetClientKey,
                                    'touch.panel.brightness',
                                    'Brightness Level',
                                    'Last reported display brightness level',
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    panelInfo.brightnessLevel,
                                    0,100,'%',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO,
                                    RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);

      // volume level
      RmsAssetParameterEnqueueLevel(assetClientKey,
                                    'touch.panel.volume.level',
                                    'Volume Level',
                                    'Master volume level',
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    panelInfo.volumeLevel,
                                    0,100,'%',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO,
                                    RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL);

      // volume mute
      RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'touch.panel.volume.mute',
                                      'Volume Mute',
                                      'Last reported volume mute state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      panelInfo.volumeMute,
                                      RMS_ALLOW_RESET_NO,
                                      FALSE,
                                      RMS_TRACK_CHANGES_NO);
      IF(panelInfo.hasBattery)
      {
        // battery level
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'touch.panel.battery.level',
                                      'Battery Level',
                                      'Last reported battery level',
                                      RMS_ASSET_PARAM_TYPE_BATTERY_LEVEL,
                                      panelInfo.batteryLevel,
                                      0,100,'%',
                                      RMS_ALLOW_RESET_NO,
                                      0,
                                      RMS_TRACK_CHANGES_YES,
                                      RMS_ASSET_PARAM_BARGRAPH_BATTERY_LEVEL);

        // populate default threshold settings for low battery condition
        threshold.name = 'Low Battery';
        threshold.comparisonOperator = RMS_ASSET_PARAM_THRESHOLD_COMPARISON_LESS_THAN_EQUAL;
        threshold.value = ITOA(RMS_TP_LOW_BATTERY_THRESHOLD); // less than 5%
        threshold.statusType = RMS_STATUS_TYPE_MAINTENANCE;
        threshold.enabled = TRUE;
        threshold.notifyOnRestore = TRUE;
        threshold.notifyOnTrip = TRUE;
        threshold.delayInterval = RMS_TP_LOW_BATTERY_THRESHOLD; // number of minute before threshold takes effect

        // add a default threshold for low battery condition
        RmsAssetParameterThresholdEnqueueEx(assetClientKey,
                                            'touch.panel.battery.level',
                                            threshold)

        // battery charging
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                        'touch.panel.battery.charging',
                                        'Battery Charging',
                                        'Last reported battery charging status',
                                        RMS_ASSET_PARAM_TYPE_BATTERY_CHARGING_STATE,
                                        panelInfo.charging,
                                        RMS_ALLOW_RESET_NO,
                                        FALSE,
                                        RMS_TRACK_CHANGES_NO);
      }

      IF(panelInfo.hasDock)
      {
        // docked status
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                        'touch.panel.docked',
                                        'Docked',
                                        'Last reported docked status',
                                        RMS_ASSET_PARAM_TYPE_DOCKING_STATE,
                                        panelInfo.docked,
                                        RMS_ALLOW_RESET_NO,
                                        FALSE,
                                        RMS_TRACK_CHANGES_YES);
      }

      IF(panelInfo.hasWireless)
      {
        // wireless channel
        RmsAssetParameterEnqueueNumber(assetClientKey,
                                       'touch.panel.wireless.channel',
                                       'Wireless Channel',
                                       'Wireless network channel',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        panelInfo.wirelessChannel,
                                        0,0,'',
                                        RMS_ALLOW_RESET_NO,
                                        0,
                                        RMS_TRACK_CHANGES_NO);

        // wireless link signal strength
        RmsAssetParameterEnqueueLevel (assetClientKey,
                                       'touch.panel.wireless.signal.strength',
                                        'Wireless Signal Strength',
                                        'Last reported wireless network signal strength',
                                        RMS_ASSET_PARAM_TYPE_SIGNAL_STRENGTH,
                                        panelInfo.wirelessSignalStrength,
                                        -99,-10,'dBm',
                                        RMS_ALLOW_RESET_NO,
                                        0,
                                        RMS_TRACK_CHANGES_NO,
                                        RMS_ASSET_PARAM_BARGRAPH_SIGNAL_STRENGTH);
     }
  }

  // submit all parameter registrations
  RmsAssetParameterSubmit(assetClientKey);
}



(***********************************************************)
(* Name:  SynchronizeAssetParameters                       *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        update/synchronize this asset parameter values   *)
(*        with RMS.                                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetParameters()
{
  // This callback method is invoked when either the RMS server connection
  // has been offline or this monitored device has been offline from some
  // amount of time.   Since the monitored parameter state values could
  // be out of sync with the RMS server, we must perform asset parameter
  // value updates for all monitored parameters so they will be in sync.
  // Update only asset monitoring parameters that may have changed in value.

  // update device online parameter value
  RmsAssetOnlineParameterUpdate(assetClientKey, DEVICE_ID(dvMonitoredDevice));

  // update asset power parameter value
  RmsAssetPowerParameterUpdate(assetClientKey,DEVICE_ID(dvMonitoredDevice));

  // if this panel supports the Gibraltar firmware (CUSTOM_EVENTS),
  // then synchronize these monitored parameter values
  IF(panelInfo.hasCustomEventSupport)
  {
    // brightness level
    RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'touch.panel.brightness',panelInfo.brightnessLevel);

    // volume level
    RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'touch.panel.volume.level',panelInfo.volumeLevel);

    // volume mute
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'touch.panel.volume.mute',panelInfo.volumeMute);

     IF(panelInfo.hasDock)
    {
      // docked status
      RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'touch.panel.docked',panelInfo.docked);
    }

    IF(panelInfo.hasBattery)
    {
      // battery level
      RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'touch.panel.battery.level',panelInfo.batteryLevel);

       // battery charging
      RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'touch.panel.battery.charging',panelInfo.charging);
    }

    IF(panelInfo.hasWireless)
    {
      // wireless channel
      RmsAssetParameterEnqueueSetValueNumber(assetClientKey,'touch.panel.wireless.channel',panelInfo.wirelessChannel);

      // wireless link signal strength
      RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'touch.panel.wireless.signal.strength',TYPE_CAST(panelInfo.wirelessSignalStrength));
    }

    // submit all the pending parameter updates now
    RmsAssetParameterUpdatesSubmit(assetClientKey);
  }
}


(***********************************************************)
(* Name:  ResetAssetParameterValue                         *)
(* Args:  parameterKey   - unique parameter key identifier *)
(*        parameterValue - new parameter value after reset *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that an asset          *)
(*        parameter value has been reset by the RMS server *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
DEFINE_FUNCTION ResetAssetParameterValue(CHAR parameterKey[],CHAR parameterValue[])
{
  // if your monitoring module performs any parameter
  // value tracking, then you may want to update the
  // tracking value based on the new reset value
  // received from the RMS server.
}


(***********************************************************)
(* Name:  RegisterAssetMetadata                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's metadata properties with   *)
(*        RMS.                                             *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetMetadata()
{
  // this is a new asset registration, register all
  // asset metadata properties now.
  RmsAssetMetadataEnqueueBoolean(assetClientKey, 'touch.panel.g4','G4 Enabled', panelInfo.isG4Panel);
  RmsAssetMetadataEnqueueBoolean(assetClientKey, 'touch.panel.headless', 'Headless', panelInfo.isHeadlessPanel);
  RmsAssetMetadataEnqueueBoolean(assetClientKey, 'touch.panel.wireless', 'Wireless', panelInfo.hasWireless);
  RmsAssetMetadataEnqueueBoolean(assetClientKey, 'touch.panel.dockable', 'Dockable', panelInfo.hasDock);
  RmsAssetMetadataEnqueueBoolean(assetClientKey, 'touch.panel.battery', 'Battery', panelInfo.hasBattery);

  // if this panel supports the Gibraltar firmware (CUSTOM_EVENTS), then register these additional metadata properties
  IF(panelInfo.hasCustomEventSupport)
  {
    RmsAssetMetadataEnqueueNumber(assetClientKey, 'touch.panel.display.timeout', 'Display Timeout', panelInfo.displayTimeout);
    RmsAssetMetadataEnqueueNumber(assetClientKey, 'touch.panel.shutdown.timeout', 'Shutdown Timeout', panelInfo.shutdownTimeout);
    RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.file.system', 'File System', panelInfo.fileSystem);
    RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.memory', 'Memory', panelInfo.memory);
    RmsAssetMetadataEnqueueNumber(assetClientKey, 'touch.panel.start.time', 'Start Time', panelInfo.startTime);
    RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.mac.address', 'MAC Address', panelInfo.macAddress);

    IF(panelInfo.hasWireless)
    {
      RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.wireless.wap.mac', 'WAP MAC Address', panelInfo.wirelessWapMacAddress);
      RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.wireless.ssid', 'Wireless SSID', panelInfo.wirelessSSID);
    }

    IF(panelInfo.hasBattery && panelInfo.batteryBaseVersion != '')
    {
      RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.battery.base.version', 'Battery Base Version', panelInfo.batteryBaseVersion);
    }
  }

  // submit metadata for registration now
  RmsAssetMetadataSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  SynchronizeAssetMetadata                         *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        update/synchronize this asset metadata properties *)
(*        with RMS if needed.                              *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetMetadata()
{
  // This callback method is invoked when either the RMS server connection
  // has been offline or this monitored device has been offline from some
  // amount of time.   Traditionally, asset metadata is relatively static
  // information and thus does not require any synchronization of values.
  // However, this callback method does provide the opportunity to perform
  // any necessary metadata updates if your implementation does include
  // any dynamic metadata values.

  // the touch panel does contain some dynamic metadata properties
  // thus during a synchronization request, we will send the latest
  // metadata registration information for these select metadata properties

  // if this panel supports the Gibraltar firmware (CUSTOM_EVENTS),
  // then synchronize these metadata properties
  IF(panelInfo.hasCustomEventSupport)
  {
    RmsAssetMetadataEnqueueNumber(assetClientKey, 'touch.panel.display.timeout', 'Display Timeout', panelInfo.displayTimeout);
    RmsAssetMetadataEnqueueNumber(assetClientKey, 'touch.panel.shutdown.timeout', 'Shutdown Timeout', panelInfo.shutdownTimeout);
    RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.file.system', 'File System', panelInfo.fileSystem);
    RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.memory', 'Memory', panelInfo.memory);
    RmsAssetMetadataEnqueueNumber(assetClientKey, 'touch.panel.start.time', 'Start Time', panelInfo.startTime);
    RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.mac.address', 'MAC Address', panelInfo.macAddress);

    IF(panelInfo.hasWireless)
    {
      RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.wireless.wap.mac', 'WAP MAC Address', panelInfo.wirelessWapMacAddress);
      RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.wireless.ssid', 'Wireless SSID', panelInfo.wirelessSSID);
    }

    IF(panelInfo.hasBattery && panelInfo.batteryBaseVersion != '')
    {
      RmsAssetMetadataEnqueueString(assetClientKey, 'touch.panel.battery.base.version', 'Battery Base Version', panelInfo.batteryBaseVersion);
    }

    // submit metadata for registration now
    RmsAssetMetadataSubmit(assetClientKey);
  }
}


(***********************************************************)
(* Name:  RegisterAssetControlMethods                      *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's control methods with RMS.  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetControlMethods()
{
  // register all asset control methods now.

  // SETUP
  RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.setup', 'Enter Setup', 'Enter setup configuration pages on touch panel user interface');

  // SLEEP
  RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.sleep', 'Sleep', 'Put the touch panel user interface into sleep mode');

  // WAKE
  RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.wake', 'Wake', 'Wake the touch panel user interface from sleep mode');

  // the following methods are not available on headless panels
  IF(!panelInfo.isHeadlessPanel)
  {
    // CALIB
    RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.calibrate', 'Calibrate', 'Calibrate the touch panel user interface');

    // BEEP / DBEEP / ABEEP / ADBEEP
    RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.beep', 'Beep', 'Signal audible beep tone on the touch panel user interface');
    RmsAssetControlMethodArgumentBoolean(assetClientKey, 'touch.panel.beep', 0, 'Double Beep', 'Enable double beep tone', FALSE);
    RmsAssetControlMethodArgumentBoolean(assetClientKey, 'touch.panel.beep', 1, 'Force Beep', 'Signal beep tone even if the touch panel is muted', TRUE);

    // G4 only control methods
    IF(panelInfo.isG4Panel)
    {
      // BRIGHTNESS LEVEL
      RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.brightness', 'Set Brightness Level', 'Set the display brightness level on the touch panel user interface');
      RmsAssetControlMethodArgumentLevel(assetClientKey, 'touch.panel.brightness', 0, 'Brightness Level', 'Available range 1-100', 70, 1, 100, 1);

      // MUTE ON/OFF
      RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.volume.mute', 'Set Volume Mute', 'Set the audio mute status on the touch panel user interface');
      RmsAssetControlMethodArgumentBoolean(assetClientKey, 'touch.panel.volume.mute', 0, 'Mute On', 'Mute ON/OFF', FALSE);

      // VOLUME LEVEL
      RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.volume.level', 'Set Volume Level', 'Set the audio volume level on the touch panel user interface');
      RmsAssetControlMethodArgumentLevel(assetClientKey, 'touch.panel.volume.level', 0, 'Volume Level', 'Available range 0-100', 50, 0, 100, 1);
    }

    // G3 only control methods
    IF(!panelInfo.isG4Panel)
    {
      // BRIGHTNESS LEVEL
      RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.brightness', 'Set Brightness Level', 'Set the display brightness level on the touch panel user interface');
      RmsAssetControlMethodArgumentLevel(assetClientKey, 'touch.panel.brightness', 0, 'Brightness Level', 'Available range 1-8', 6, 1, 8, 1);

      // RESET
      RmsAssetControlMethodEnqueue(assetClientKey, 'touch.panel.reset', 'Reset Panel', 'Reset the touch panel user interface');
    }
  }

  // when done enqueuing all asset control methods and
  // arguments for this asset, we just need to submit
  // them to finalize and register them with the RMS server
  RmsAssetControlMethodsSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  ExecuteAssetControlMethod                        *)
(* Args:  methodKey - unique method key that was executed  *)
(*        arguments - array of argument values invoked     *)
(*                    with the execution of this method.   *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it should         *)
(*        fullfill the execution of one of this asset's    *)
(*        control methods.                                 *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION ExecuteAssetControlMethod(CHAR methodKey[], CHAR arguments[])
{
  SELECT
  {
    // CALIB
    ACTIVE(methodKey == 'touch.panel.calibrate'):
    {
      IF(panelInfo.isG4Panel)
      {
        SEND_COMMAND dvMonitoredDevice,'^CAL'
      }
      ELSE
      {
        SEND_COMMAND dvMonitoredDevice,'CALIB'
      }
    }

    // SETUP
    ACTIVE(methodKey == 'touch.panel.setup'):
    {
      SEND_COMMAND dvMonitoredDevice,'SETUP'
    }

    // BEEP / DBEEP / ABEEP / ADBEEP
    ACTIVE(methodKey == 'touch.panel.beep'):
    {
      STACK_VAR CHAR doubleBeepArgument[5];
                CHAR forceBeepArgument[5];

      doubleBeepArgument = RmsParseCmdParam(arguments);
      forceBeepArgument = RmsParseCmdParam(arguments);

      IF(RmsBooleanValue(doubleBeepArgument))
      {
        IF(RmsBooleanValue(forceBeepArgument))
        {
          SEND_COMMAND dvMonitoredDevice,'ADBEEP'
        }
        ELSE
        {
          SEND_COMMAND dvMonitoredDevice,'DBEEP'
        }
      }
      ELSE
      {
        IF(RmsBooleanValue(forceBeepArgument))
        {
          SEND_COMMAND dvMonitoredDevice,'ABEEP'
        }
        ELSE
        {
          SEND_COMMAND dvMonitoredDevice,'BEEP'
        }
      }
    }

    // SLEEP
    ACTIVE(methodKey == 'touch.panel.sleep'):
    {
      SEND_COMMAND dvMonitoredDevice,'SLEEP'
    }

    // WAKE
    ACTIVE(methodKey == 'touch.panel.wake'):
    {
      SEND_COMMAND dvMonitoredDevice,'WAKE'
    }

    // BRIGHTNESS LEVEL 1-100 (G4) or 1-8 (G3)
    ACTIVE(methodKey == 'touch.panel.brightness'):
    {
      STACK_VAR CHAR brightnessArgument[5];
      brightnessArgument = RmsParseCmdParam(arguments);
      SEND_COMMAND dvMonitoredDevice,"'BRIT-',brightnessArgument"
    }

    // MUTE ON/OFF (G4 only)
    ACTIVE(panelInfo.isG4Panel && methodKey == 'touch.panel.volume.mute'):
    {
      STACK_VAR CHAR muteArgument[5];
      muteArgument = RmsParseCmdParam(arguments);
      SEND_COMMAND dvMonitoredDevice,"'^MUT-',ITOA(RmsBooleanValue(muteArgument))"
    }

    // VOL LEVEL 0-100 (G4 only)
    ACTIVE(panelInfo.isG4Panel && methodKey == 'touch.panel.volume.level'):
    {
      STACK_VAR CHAR volumeArgument[5];
      volumeArgument = RmsParseCmdParam(arguments);
      SEND_COMMAND dvMonitoredDevice,"'^VOL-',volumeArgument"
    }

    // RESET (G3 only)
    ACTIVE(!panelInfo.isG4Panel && methodKey == 'touch.panel.reset'):
    {
      SEND_COMMAND dvMonitoredDevice,"'RESET'"
    }
  }
}


(***********************************************************)
(* Name:  SystemPowerChanged                               *)
(* Args:  powerOn - boolean value representing ON/OFF      *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that the SYSTEM POWER  *)
(*        state has changed states.                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SystemPowerChanged(CHAR powerOn)
{
  // optionally implement logic based on
  // system power state.
}


(***********************************************************)
(* Name:  SystemModeChanged                                *)
(* Args:  modeName - string value representing mode change *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that the SYSTEM MODE   *)
(*        state has changed states.                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SystemModeChanged(CHAR modeName[])
{
  // optionally implement logic based on
  // newly selected system mode name.
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

DATA_EVENT[vdvRMS]
{
  ONLINE :
  {
    IF(panelInfo.isG4Panel && panelInfo.hasCustomEventSupport && DEVICE_ID(dvMonitoredDevice) && !TIMELINE_ACTIVE(TL_MONITOR))
    {
      TIMELINE_CREATE(TL_MONITOR,PanelMonitoringTimeArray,1,TIMELINE_RELATIVE,TIMELINE_REPEAT);
    }
  }
  OFFLINE :
  {
    IF(TIMELINE_ACTIVE(TL_MONITOR))
    {
      TIMELINE_KILL(TL_MONITOR);
    }
  }
}

//
// when the touch panel device comes online
// determine the touch panel's capabilities
//
DATA_EVENT[dvMonitoredDevice]
{
  ONLINE:
  {
    STACK_VAR DEV_INFO_STRUCT deviceInfo;
              CHAR versionMajor[10];
              CHAR versionMinor[10];
              INTEGER vMajor;
              INTEGER vMinor;

    // is this touch panel a G4 panel?  (all G4 panels are above the 256 device id)
    panelInfo.isG4Panel = (DEVICE_ID(DATA.DEVICE) >= 256);

    // is this touch panel a headless panel?
    panelInfo.isHeadlessPanel = (RmsDeviceIdInList(DEVICE_ID(DATA.DEVICE),DEVICE_ID_LIST_HEADLESS_PANEL) > 0);

    // is this touch panel a protable device?
    panelInfo.isPortablePanel = (RmsDeviceIdInList(DEVICE_ID(DATA.DEVICE),DEVICE_ID_LIST_PORTABLE_PANEL) > 0);

    // does this touch panel support a wireless network connection?
    panelInfo.hasWireless = (panelInfo.isPortablePanel); // assume if the panel is portable that is has a wireless connection

    // does this touch panel support a battery?
    panelInfo.hasBattery = (panelInfo.isPortablePanel); // assume if the panel is portable that is has a battery

    // does this touch panel support docking or cradle?
    panelInfo.hasDock = (panelInfo.isPortablePanel); // assume if the panel is portable that is has docking capability

    // reset last known monitor tracking variables
    panelInfo.docked = FALSE;
    panelInfo.displayTimeout = 0;
    panelInfo.shutdownTimeout = 0;
    panelInfo.wirelessChannel = 0;
    panelInfo.wirelessSignalStrength = 0;
    panelInfo.wirelessWapMacAddress = '';
    panelInfo.wirelessSSID = '';
    panelInfo.macAddress = '';
    panelInfo.batteryLevel = 0;
    panelInfo.batteryBaseVersion = '';
    panelInfo.brightnessLevel = 0;
    panelInfo.docked = FALSE;
    panelInfo.volumeLevel = 0;
    panelInfo.volumeMute = 0;
    panelInfo.charging = FALSE;
    panelInfo.fileSystem = '';
    panelInfo.memory = '';
    panelInfo.startTime = '';
    panelInfo.hasCustomEventSupport = FALSE;

    // if this is a G4 panel, then we need to find out if it is running
    // a Gilbratar level fimware that adds more advanced monitoring capabilities.
    IF(panelInfo.isG4Panel)
    {
      // get device info
      DEVICE_INFO(DATA.DEVICE, deviceInfo);

      // determine firmware version major and minor values
      versionMajor = RmsParseCmdParamEx(deviceInfo.VERSION, '.');
      REMOVE_STRING(versionMajor,'v',1);  // eliminate any 'v' prefix character
      versionMinor = RmsParseCmdParamEx(deviceInfo.VERSION, '.');
      vMajor = ATOI(versionMajor);
      vMinor = ATOI(versionMinor);

      // if this touch panel contains the Gibraltar firmware v2.86xx or above,
      // then we can enable this panel for advanced monitoring capabilities.
      IF(vMajor > 2 || (vMajor == 2 && vMinor >= 86))
      {
        panelInfo.hasCustomEventSupport = TRUE;

        // create the panel monitoring timeline to send query commands to the
        // touch panel device to interrogate the panel for monitoring information
        // (NOTE: this only applies to panels running the Gibraltar firmware v2.86xx or above)
        IF(!TIMELINE_ACTIVE(TL_MONITOR))
        {
        	IF(DEVICE_ID(vdvRMS))
        	{
          	TIMELINE_CREATE(TL_MONITOR,PanelMonitoringTimeArray,1,TIMELINE_RELATIVE,TIMELINE_REPEAT);
          }
        }
      }
      ELSE
      {
        Debug("'Please note, additional RMS monitoring capabilities can be enabled on this ... '");
        Debug("'... touch panel if the panel firmware is upgraded to 2.86 or above.'");
        panelInfo.hasCustomEventSupport = FALSE;
      }
    }

    // the device online parameter is updated to
    // the ONLINE state in the callback method:
    //   SynchronizeAssetParameters()
    // no further action is needed here in the ONLINE
    // data event for the device online asset parameter
  }
  OFFLINE:
  {
    // if a panel monitoring timeline was created and is running, then permanently
    // destroy the panel monitoring timeline while the panel is offline.
    IF(TIMELINE_ACTIVE(TL_MONITOR))
    {
      TIMELINE_KILL(TL_MONITOR);
    }

    IF(assetRegistered)
    {
      // update device online parameter value
      RmsAssetOnlineParameterUpdate(assetClientKey, DEVICE_ID(dvMonitoredDevice));

      // update asset power parameter value ot 'OFF'
      RmsAssetPowerParameterUpdate(assetClientKey,FALSE);
    }
  }
}


//
// monitor touch panel docking state
//
CHANNEL_EVENT[dvMonitoredDevice,TP_CHANNEL_DOCKED]
{
  ON:
  {
    IF(panelInfo.hasDock)
    {
      DEBUG('>>>>> Touch Panel is DOCKED');

      // send docked status to RMS
      RmsAssetParameterSetValue(assetClientKey,'touch.panel.docked','true');
    }
  }
  OFF:
  {
    IF(panelInfo.hasDock)
    {
      DEBUG('>>>>> Touch Panel is UN-DOCKED');

      // send un-docked status to RMS
      RmsAssetParameterSetValue(assetClientKey,'touch.panel.docked','false');
    }
  }
}


//
// monitor touch panel battery level
//
LEVEL_EVENT[dvMonitoredDevice,TP_LEVEL_BATTERY]
{
  // if the touch panle supports a battery and
  // the device is currently online, then
  // send parameter update to RMS
  IF(panelInfo.hasBattery && DEVICE_ID(LEVEL.INPUT.DEVICE))
  {
    // we want to limit the parameter update notifications
    // sent to the RMS server, so we will only send the update
    // if the change delta exceeds a defined minimum threshold.
    IF(ABS_VALUE((LEVEL.VALUE - panelInfo.batteryLevel)) >= RMS_BATTERY_MINIMUM_CHANGE_THRESHOLD)
    {
      DEBUG("'>>>>> Touch Panel BATTERY LEVEL: ',ITOA(LEVEL.VALUE)");

      // send battery level update to RMS
      RmsAssetParameterSetValue(assetClientKey,'touch.panel.battery.level',ITOA(LEVEL.VALUE));

      // record last sent battery level
      panelInfo.batteryLevel = LEVEL.VALUE;
    }
  }
}



// CUSTOM_EVENT commands with 0 address (panel properties)
CUSTOM_EVENT[dvMonitoredDevice,0,1302] // ?DTO - Display Timeout
CUSTOM_EVENT[dvMonitoredDevice,0,1303] // ?BRT - Brightness
CUSTOM_EVENT[dvMonitoredDevice,0,1304] // ?PIF - Custom Info <Filesystem, RAM, Start Time>
CUSTOM_EVENT[dvMonitoredDevice,0,1305] // ?MUT - Volume Mute
CUSTOM_EVENT[dvMonitoredDevice,0,1306] // ?VOL - Volume Level
CUSTOM_EVENT[dvMonitoredDevice,0,1307] // ?STO - Shutdown Timeout
CUSTOM_EVENT[dvMonitoredDevice,0,1308] // ?CHR - Charging Status
CUSTOM_EVENT[dvMonitoredDevice,0,1309] // ?WIF - WiFi Info
CUSTOM_EVENT[dvMonitoredDevice,0,1313] // ?BBV - Battery Base Version
CUSTOM_EVENT[dvMonitoredDevice,0,1315] // ?MAC - MAC addresses
{
  STACK_VAR CHAR temp[RMS_MAX_PARAM_LEN];
            SLONG tempValue;

  //DEBUG("'>>>>> Touch Panel CUSTOM EVENT ID=[',ITOA(CUSTOM.TYPE),'] VAL1: ',ITOA(CUSTOM.VALUE1),' / TEXT: ',CUSTOM.TEXT");

  SWITCH(CUSTOM.TYPE)
  {
    CASE 1302:  // ?DTO - Display Timeout
    {
      IF(TYPE_CAST(CUSTOM.VALUE1) != panelInfo.displayTimeout)
      {
        panelInfo.displayTimeout = TYPE_CAST(CUSTOM.VALUE1);
        RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.display.timeout', ITOA(panelInfo.displayTimeout));
      }
      BREAK;
    }
    CASE 1303:  // ?BRT - Brightness
    {
      IF(TYPE_CAST(CUSTOM.VALUE1) != panelInfo.brightnessLevel)
      {
        panelInfo.brightnessLevel = TYPE_CAST(CUSTOM.VALUE1);
        RmsAssetParameterSetValueLevel(assetClientKey,'touch.panel.brightness',panelInfo.brightnessLevel);
      }
      BREAK;
    }
    CASE 1304:  // ?PIF - Custom Info <Filesystem, RAM, Start Time>
    {
      temp = RmsParseCmdParam(CUSTOM.TEXT);
      IF(temp != panelInfo.fileSystem)
      {
        panelInfo.fileSystem = temp;
        RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.file.system', panelInfo.fileSystem);
      }

      temp = RmsParseCmdParam(CUSTOM.TEXT);
      IF(temp != panelInfo.memory)
      {
        panelInfo.memory = temp;
        RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.memory', panelInfo.memory);
      }

      temp = RmsParseCmdParam(CUSTOM.TEXT);
      IF(temp != panelInfo.startTime)
      {
        panelInfo.startTime = temp;
        RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.start.time', ITOA(panelInfo.startTime));
      }

      //CUSTOM.TEXT
      BREAK;
    }
    CASE 1305:  // ?MUT - Volume Mute
    {
      IF(TYPE_CAST(CUSTOM.VALUE1) != panelInfo.volumeMute)
      {
        panelInfo.volumeMute = TYPE_CAST(CUSTOM.VALUE1);
        RmsAssetParameterSetValueBoolean(assetClientKey,'touch.panel.volume.mute',panelInfo.volumeMute);
      }
      BREAK;
    }
    CASE 1306:  // ?VOL - Volume Level
    {
      IF(TYPE_CAST(CUSTOM.VALUE1) != panelInfo.volumeLevel)
      {
        panelInfo.volumeLevel = TYPE_CAST(CUSTOM.VALUE1);
        RmsAssetParameterSetValueLevel(assetClientKey,'touch.panel.volume.level',panelInfo.volumeLevel);
      }
      BREAK;
    }
    CASE 1307:  // ?STO - Shutdown Timeout
    {
      IF(TYPE_CAST(CUSTOM.VALUE1) != panelInfo.shutdownTimeout)
      {
        panelInfo.shutdownTimeout = TYPE_CAST(CUSTOM.VALUE1);
        RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.shutdown.timeout', ITOA(panelInfo.shutdownTimeout));
      }
      BREAK;
    }
    CASE 1308:  // ?CHR - Charging Status
    {
      IF(TYPE_CAST(CUSTOM.VALUE1) != panelInfo.charging)
      {
        panelInfo.charging = TYPE_CAST(CUSTOM.VALUE1);
        RmsAssetParameterSetValueBoolean(assetClientKey,'touch.panel.battery.charging',panelInfo.charging);
      }

      //-----------------------------------------------------------
      // We are currently obtaining battery level using the touch
      // panel's output LEVEL for battery; however, this metric
      // could be used instead of the LEVEL if desired.
      //-----------------------------------------------------------
      //IF(TYPE_CAST(CUSTOM.VALUE2) != panelInfo.batteryLevel)
      //{
      //  // only update the signal strength parameter if the value has changed by
      //  // a certain factor.
      //  IF(ABS_VALUE(CUSTOM.VALUE2 - panelInfo.batteryLevel) >= RMS_BATTERY_MINIMUM_CHANGE_THRESHOLD)
      //  {
      //    panelInfo.batteryLevel = TYPE_CAST(CUSTOM.VALUE2);
      //
      //    // battery level
      //    RmsAssetParameterSetValueLevel(assetClientKey,'touch.panel.battery.level',panelInfo.batteryLevel);
      //  }
      //}
      BREAK;
    }
    CASE 1309:  // ?WIF - WiFi Info
    {
      // Text=<WAP MAC address>,<SSID>,<Channel #>,<Signal Level Value>

      // Wireless WAP MAC Address
      temp = RmsParseCmdParam(CUSTOM.TEXT);
      IF(temp != panelInfo.wirelessWapMacAddress)
      {
        panelInfo.wirelessWapMacAddress = temp;
        IF(panelInfo.hasWireless)
        {
          RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.wireless.wap.mac', panelInfo.wirelessWapMacAddress);
        }
      }

      // Wireless SSID
      temp = RmsParseCmdParam(CUSTOM.TEXT);
      IF(temp != panelInfo.wirelessSSID)
      {
        panelInfo.wirelessSSID = temp;
        IF(panelInfo.hasWireless)
        {
          RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.wireless.ssid', panelInfo.wirelessSSID);
        }
      }

      // Wirelss Channel #
      temp = RmsParseCmdParam(CUSTOM.TEXT);
      tempValue = ATOI(temp);
      IF(tempValue != TYPE_CAST(panelInfo.wirelessChannel))
      {
        panelInfo.wirelessChannel = ATOI(temp);
        RmsAssetParameterSetValueNumber(assetClientKey,'touch.panel.wireless.channel',panelInfo.wirelessChannel);
      }

      // Wirelss Channel #
      temp = RmsParseCmdParam(CUSTOM.TEXT);
      tempValue = ATOI(temp);
      IF(tempValue != panelInfo.wirelessSignalStrength)
      {
        // only update the signal strength parameter if the value has changed by
        // a certain factor.
        IF(ABS_VALUE(tempValue - panelInfo.wirelessSignalStrength) >= RMS_WIRELESS_SIGNAL_STRENGTH_MINIMUM_CHANGE_THRESHOLD)
        {
          panelInfo.wirelessSignalStrength = ATOI(temp);
          RmsAssetParameterSetValueLevel(assetClientKey,'touch.panel.wireless.signal.strength',panelInfo.wirelessSignalStrength);
        }
      }

      BREAK;
    }
    CASE 1313:  // ?BBV - Battery Base Version
    {
      // Battery Base Version
      IF(CUSTOM.TEXT != panelInfo.batteryBaseVersion)
      {
        panelInfo.batteryBaseVersion = CUSTOM.TEXT;

        // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
        IF(panelInfo.hasBattery && panelInfo.batteryBaseVersion != '')
        {
          RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.battery.base.version', panelInfo.batteryBaseVersion);
        }
      }
      BREAK;
    }
    CASE 1315:  // ?MAC - MAC addresses
    {
      // MAC Address
      IF(CUSTOM.TEXT != panelInfo.macAddress)
      {
        panelInfo.macAddress = CUSTOM.TEXT;
        RmsAssetMetadataUpdateValue(assetClientKey, 'touch.panel.mac.address', panelInfo.macAddress);
      }
      BREAK;
    }
  }
}


// capture all events touch panel monitoring timeline
// (NOTE: this timeline should only be started on panels running
//        the Gibraltar firmware v2.86xx or above)
TIMELINE_EVENT[TL_MONITOR]
{
  IF(panelInfo.hasCustomEventSupport)
  {
    //DEBUG('>>>>> Touch Panel monitoring timeline querying TP for status...');

    // send query commands to obtain panel status info
    SEND_COMMAND dvMonitoredDevice, '?DTO';  // Display Timeout
    SEND_COMMAND dvMonitoredDevice, '?BRT';  // Brightness
    SEND_COMMAND dvMonitoredDevice, '?PIF';  // Custom Info <Filesystem, RAM, Start Time>
    SEND_COMMAND dvMonitoredDevice, '?MUT';  // Volume Mute
    SEND_COMMAND dvMonitoredDevice, '?VOL';  // Volume Level
    SEND_COMMAND dvMonitoredDevice, '?STO';  // Shutdown Timeout
    SEND_COMMAND dvMonitoredDevice, '?CHR';  // Charging Status
    SEND_COMMAND dvMonitoredDevice, '?WIF';  // WiFi Info
    SEND_COMMAND dvMonitoredDevice, '?BBV';  // Battery Base Version
    SEND_COMMAND dvMonitoredDevice, '?MAC';  // MAC Address
  }
  ELSE
  {
    // warning debug message
    DEBUG('>>>> ATTENTION, this panel monitoring timeline should NOT BE RUNNING!');
    DEBUG('>>>> ATTENTION, this panel firmware does not support CUSTOM_EVENTS!');
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
