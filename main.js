// Cuz I'm not good enough
const cp = require('child_process')

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
const env = {
  DEVICE_ID
}

for (const key of Object.keys(config).filter(key => key !== 'annoyingAds')) {
  for (const subKey of Object.keys(config[key])) {
    env[`${key.toUpperCase()}_${subKey.toUpperCase()}`] = config[key][subKey];
  }
}

env.ANNOYING_ADS = ''
for (const ad of config.annoyingAds) {
  env.ANNOYING_ADS += `${ad.scope};${ad.color};${ad.minimum};${ad.x};${ad.y} `
}

let envString = ''
for (const key of Object.keys(env)) {
  envString = `${envString}${key}="${env[key]}" `;
}

console.log(`${envString} ./main.sh`)
