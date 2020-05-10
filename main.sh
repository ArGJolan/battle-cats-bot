#!/bin/bash

SLEEP_TIME=25
RESET=true
CAT_FOOD=0

function pixel_is () {
  PIXEL_X=$1
  PIXEL_Y=$2
  COLOR=$3

  adb -s $DEVICE_ID shell screencap -p /sdcard/$DEVICE_ID.png > /dev/null && adb -s $DEVICE_ID pull /sdcard/$DEVICE_ID.png > /dev/null

  if convert $DEVICE_ID.png -crop "1x1+${PIXEL_X}+${PIXEL_Y}" txt:- | grep $COLOR > /dev/null ; then
    return 0
  else
    return 1
  fi
}

function launch_app () {
  adb -s $DEVICE_ID shell monkey -p jp.co.ponos.battlecatsen -c android.intent.category.LAUNCHER 1 > /dev/null 2> /dev/null
}

function quit_app () {
  adb -s $DEVICE_ID shell am force-stop jp.co.ponos.battlecatsen > /dev/null 2> /dev/null
}

function tap () {
  TAP_X=$1
  TAP_Y=$2

  adb -s $DEVICE_ID shell input tap $TAP_X $TAP_Y
}

function wait_for_cat_food () {
  while ! pixel_is $CATFOOD_X $CATFOOD_Y $CATFOOD_COLOR ; do
    echo -e "⏳\tWaiting for cat food to be shown"
  done
  echo -e "🍜\tCat food shown!"
}

function wait_for_cat_food_shop () {
  while ! pixel_is $CATFOODSHOP_X $CATFOODSHOP_Y $CATFOODSHOP_COLOR ; do
    echo -e "⏳\tWaiting for cat food shop to be shown"
  done
  echo -e "🛒\tCat food shop shown!"
}

function spam_back_until_done () {
  count=0
  while ! pixel_is $ADSUCCESSOK_X $ADSUCCESSOK_Y $ADSUCCESSOK_COLOR ; do
    echo -e "⏳\tWaiting for the ad to be hidden..."
    if [[ $count -gt 20 ]]; then
      echo -e "🚨\tSomething went wrong"
      SLEEP_TIME=$((SLEEP_TIME+5))
      RESET=true
      return 1
    fi
    if [[ $count -gt 15 ]]; then
      echo -e "❌\tTrying to exit with cross..."
      tap $CROSS_X $CROSS_Y
      sleep 2
      adb -s $DEVICE_ID shell input keyevent KEYCODE_BACK
    else
      adb -s $DEVICE_ID shell input keyevent KEYCODE_BACK
    fi
    sleep 1
    count=$((count+1))
  done
  CAT_FOOD=$((CAT_FOOD+1))
  echo -e "✅\tCat food aquired ($CAT_FOOD total)!"
}

function farm () {
  echo -e "🚜\tFarming!"
  wait_for_cat_food
  tap $CATFOOD_X $CATFOOD_Y
  wait_for_cat_food_shop
  tap $CATFOODSHOP_X $CATFOODSHOP_Y
  echo -e "💸\tAd launched, sleeping ${SLEEP_TIME}s..."
  
  sleep $SLEEP_TIME

  spam_back_until_done
  tap $ADSUCCESSOK_X $ADSUCCESSOK_Y
}

function wait_for_intro () {
  while ! pixel_is $INTRO_X $INTRO_Y $INTRO_COLOR ; do
    echo -e "⏳\tWaiting for intro..."
  done
  echo -e "🖥\tIntro is playing!"
}

function wait_for_menu () {
  while ! pixel_is $MENU_X $MENU_Y $MENU_COLOR ; do
    echo -e "⏳\tWaiting for menu..."
  done
  echo -e "🖥\tOn main menu!"
}

function init () {
  echo -e "🔄\tRestarting!"
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
  elif [[ $SLEEP_TIME -gt 25 ]]; then
    SLEEP_TIME=$((SLEEP_TIME-5))
  fi
  farm
done
