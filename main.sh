#!/bin/bash

# List all packages
# adb shell 'pm list packages -f' | sed -e 's/.*=//' | sort

function pixel_is() {
  PIXEL_X=$1
  PIXEL_Y=$2

  echo "X: $1, Y:$2"
}

function launch_app() {
  adb shell monkey -p jp.co.ponos.battlecatsen -c android.intent.category.LAUNCHER 1
}

# launch_app


