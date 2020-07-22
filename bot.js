const fs = require('fs');
const cp = require('child_process');

const {
  PROFILE,
  DEVICE_ID,
} = process.env

if (!PROFILE || !DEVICE_ID) {
  console.error('You need to set PROFILE and DEVICE_ID env variables');
  console.log(cp.execSync('adb devices -l').toString());
  process.exit();
}

const config = require(`./config/${PROFILE}`)

const adb = (command) => {
  cp.execSync(`adb -s ${DEVICE_ID} ${command}`)
}

const pixelIs = ({ x, y, color }) => {
  try {
    adb(`shell screencap -p /sdcard/${PROFILE}.png > /dev/null`)
    adb(`pull /sdcard/${PROFILE}.png > /dev/null`)
    cp.execSync(`open ${PROFILE}.png`)
  } catch (e) {
    console.error('Could not take screenshot', e)
  }
  try {
    cp.execSync(`convert ${PROFILE}.png -crop "1x1+${x}+${y}" txt:- | grep ${color} > /dev/null`)
    return true;
  } catch (err) {
    console.log(cp.execSync(`convert ${PROFILE}.png -crop "1x1+${x}+${y}" txt:-`).toString())
    return false;
  }
}

console.log(pixelIs({ x: 876, y: 451, color: 'E3AB23FF' }));
