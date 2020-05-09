#!/bin/bash

# List all packages
# adb shell 'pm list packages -f' | sed -e 's/.*=//' | sort

function pixel_is () {
  PIXEL_X=$1
  PIXEL_Y=$2
  COLOR=$3

  adb shell screencap -p /sdcard/screen.png > /dev/null && adb pull /sdcard/screen.png > /dev/null

  if convert screen.png -crop "1x1+${PIXEL_X}+${PIXEL_Y}" txt:- | grep $COLOR > /dev/null ; then
    return 0
  else
    return 1
  fi
}

function launch_app () {
  adb shell monkey -p jp.co.ponos.battlecatsen -c android.intent.category.LAUNCHER 1 > /dev/null 2> /dev/null
}

function quit_app () {
  adb shell am force-stop jp.co.ponos.battlecatsen > /dev/null 2> /dev/null
}

function tap () {
  TAP_X=$1
  TAP_Y=$2

  adb shell input tap $TAP_X $TAP_Y
}

function wait_for_cat_food () {
  while ! pixel_is 1222 700 C12400FF ; do
    echo "Waiting for cat food to be shown"
  done
  echo "Cat food shown!"
}

function wait_for_cat_food_shop () {
  while ! pixel_is 682 216 F36906FF ; do
    echo "Waiting for cat food shop to be shown"
  done
  echo "Cat food shop shown!"
}

function spam_back_until_done () {
  count=0
  while ! pixel_is 876 434 FBC123FF ; do
    echo "Waiting for the ad to be hidden..."
    if [[ $count -gt 15 ]]; then
      echo "Trying to exit with cross..."
      tap 1350 42
      sleep 2
      adb shell input keyevent KEYCODE_BACK
    else
      adb shell input keyevent KEYCODE_BACK
    fi
    count=$((count+1))
  done
  echo "Ad is hidden"
}

function farm () {
  echo "Farming!"
  wait_for_cat_food
  tap 1222 700
  wait_for_cat_food_shop
  tap 682 216
  echo "Ad launched, sleeping..."
  
  sleep 15

  spam_back_until_done
  tap 876 434
  echo "Cycle done!"
}

function wait_for_intro () {
  while ! pixel_is 1373 671 FFFFFFFF ; do
    echo "Waiting for intro..."
  done
  echo "Intro is playing!"
}

function wait_for_menu () {
  while ! pixel_is 700 437 FFFFFFFF ; do
    echo "Waiting for menu..."
  done
  echo "On main menu!"
}

quit_app
launch_app

wait_for_intro
tap 1373 671 # Skip button

wait_for_menu
tap 700 437 # Click play

sleep 5
tap 850 470 # Click on default level

while true ; do
  farm
done
