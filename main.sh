#!/bin/bash

SLEEP_TIME=10
RESET=true
CAT_FOOD=0

function debug () {
  echo -e $1
  echo -e $1 > $DEVICE_ID.logs
  echo -e $1 >> $DEVICE_ID.full.logs
}

function tap () {
  TAP_X=$1
  TAP_Y=$2

  adb -s $DEVICE_ID shell input tap $TAP_X $TAP_Y
}

function handle_annoying_ad () {
  if [[ -z "$ANNOYING_ADS" ]]; then
    return 0
  fi

  screenshot
  IFS=' ' read -r -a ANNOYING_ADS_ARRAY <<< "${ANNOYING_ADS}"

  for ANNOYING_AD in "${ANNOYING_ADS_ARRAY[@]}"
  do
    IFS=';' read -r -a ANNOYING_AD_ELEMENTS <<< "${ANNOYING_AD}"
    if [[ $(convert $DEVICE_ID.png -crop "${ANNOYING_AD_ELEMENTS[0]}" txt:- | grep ${ANNOYING_AD_ELEMENTS[1]} |  wc -l) -gt ${ANNOYING_AD_ELEMENTS[2]} ]]; then
      tap ${ANNOYING_AD_ELEMENTS[3]} ${ANNOYING_AD_ELEMENTS[4]}
      echo -e "♋️\tClosed cancer!"
      sleep 5
    fi
  done
}

function battlecats_active () {
  if ! adb devices | grep $DEVICE_ID > /dev/null; then
    echo -e "⚠️\tDevice not plugged, sleeping 1 minute..."
    sleep 60
    return 1
  fi

  if ! adb -s $DEVICE_ID shell dumpsys window windows | grep -E 'mSurface|mCutFocus|mFocusedApp|mHoldScreenWindow' | grep jp.co.ponos.battlecatsen > /dev/null ; then
    echo -e "⏳\tNot on battle cats, sleeping 10 seconds..."
    sleep 10
    return 1
  fi

  return 0
}

function screenshot () {
  adb -s $DEVICE_ID shell screencap -p /sdcard/$DEVICE_ID.png > /dev/null && adb -s $DEVICE_ID pull /sdcard/$DEVICE_ID.png > /dev/null
}

function pixel_is () {
  PIXEL_X=$1
  PIXEL_Y=$2
  COLOR=$3

  while ! battlecats_active ; do sleep 1 ; done

  screenshot

  if convert $DEVICE_ID.png -crop "1x1+${PIXEL_X}+${PIXEL_Y}" txt:- | grep $COLOR > /dev/null ; then
    return 0
  else
    OUTPUT=$(convert $DEVICE_ID.png -crop "1x1+${PIXEL_X}+${PIXEL_Y}" txt:-)
    ACTUAL_PIXEL_COLOR=$(echo $OUTPUT | cut -d "#" -f 3 | cut -d " " -f 1)
    return 1
  fi
}

function launch_app () {
  adb -s $DEVICE_ID shell monkey -p jp.co.ponos.battlecatsen -c android.intent.category.LAUNCHER 1 > /dev/null 2> /dev/null
}

function quit_app () {
  adb -s $DEVICE_ID shell am force-stop jp.co.ponos.battlecatsen > /dev/null 2> /dev/null
}

function reset_after_count () {
  count=$((count+1))
  if [[ $count -gt $1 ]]; then
    RESET=true
    return 1
  fi
  return 0
}

function wait_for_cat_food () {
  count=0
  while ! pixel_is $CATFOOD_X $CATFOOD_Y $CATFOOD_COLOR ; do
    reset_after_count 25 || return 1
    debug "⏳\tWaiting for cat food to be shown (expecting $CATFOOD_COLOR, got $ACTUAL_PIXEL_COLOR)"
  done
  debug "🍜\tCat food shown!"
}

function wait_for_cat_food_shop () {
  count=0
  while ! pixel_is $CATFOODSHOP_X $CATFOODSHOP_Y $CATFOODSHOP_COLOR ; do
    reset_after_count 10 || return 1
    debug "⏳\tWaiting for cat food shop to be shown (expecting $CATFOODSHOP_COLOR, got $ACTUAL_PIXEL_COLOR)"
  done
  debug "🛒\tCat food shop shown!"
}

function spam_back_until_done () {
  count=0
  while ! pixel_is $ADSUCCESSOK_X $ADSUCCESSOK_Y $ADSUCCESSOK_COLOR ; do
    debug "⏳\tWaiting for the ad to be hidden... (expecting $ADSUCCESSOK_COLOR, got $ACTUAL_PIXEL_COLOR)"
    if [[ $count -gt 15 ]]; then
      debug "🚨\tSomething went wrong"
      SLEEP_TIME=$((SLEEP_TIME+5))
      RESET=true
      return 1
    fi
    if [[ $count -gt 10 ]]; then
      debug "❌\tTrying to exit with cross..."
      tap $CROSS_X $CROSS_Y
      sleep 2
      adb -s $DEVICE_ID shell input keyevent KEYCODE_BACK
    else
      adb -s $DEVICE_ID shell input keyevent KEYCODE_BACK
    fi
    handle_annoying_ad
    count=$((count+1))
  done
  CAT_FOOD=$((CAT_FOOD+1))
  debug "✅\tCat food aquired in ${SECONDS}s ($CAT_FOOD total)!"
}

function farm () {
  SECONDS=0
  debug "🚜\tFarming!"
  wait_for_cat_food || return 1
  tap $CATFOOD_X $CATFOOD_Y
  wait_for_cat_food_shop || return 1
  tap $CATFOODSHOP_X $CATFOODSHOP_Y
  debug "💸\tAd launched, sleeping ${SLEEP_TIME}s..."
  
  sleep $SLEEP_TIME

  spam_back_until_done || return 1
  tap $ADSUCCESSOK_X $ADSUCCESSOK_Y
}

function wait_for_intro () {
  while ! pixel_is $INTRO_X $INTRO_Y $INTRO_COLOR ; do
    debug "⏳\tWaiting for intro... (expecting $INTRO_COLOR, got $ACTUAL_PIXEL_COLOR)"
  done
  debug "🖥\tIntro is playing!"
}

function wait_for_menu () {
  while ! pixel_is $MENU_X $MENU_Y $MENU_COLOR ; do
    debug "⏳\tWaiting for menu... (expecting $MENU_COLOR, got $ACTUAL_PIXEL_COLOR)"
  done
  debug "🖥\tOn main menu!"
}

function init () {
  debug "🔄\tRestarting!"
  quit_app
  launch_app

  wait_for_intro
  tap $INTRO_X $INTRO_Y # Skip button

  wait_for_menu
  tap $MENU_X $MENU_Y # Click play

  sleep 5
  tap $DEFAULTLEVEL_X $DEFAULTLEVEL_Y # Click on default level
}

while true ; do
  if [[ $RESET == "true" ]]; then
    RESET=false
    init
  elif [[ $SLEEP_TIME -gt 10 ]]; then
    SLEEP_TIME=$((SLEEP_TIME-5))
  fi
  farm
done
