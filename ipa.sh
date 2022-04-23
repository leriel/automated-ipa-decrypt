#!/bin/bash

# Fully automated ipa decrypt*
#
# *(but set device screen to sleep 5min/never)

# What i have in place:
# ios 14.2 device:
#   * unc0ver 6.1.2 installed via sideloadly (8.x.x for some reason didn't work on my device)
#   * cydia (via unc0ver, make sure to check option)
#   * openssh (via cydia)
#   * frida (via cydia)
# computer:
#   * curl, jq
#   * ipatool (https://github.com/majd/ipatool/)
#   * being logged via ipatool auth login. Need to provide email+password+2fa only first time you login. After that you just login via email+password
#   * device connected via usb and computer trusted
#   * bagbak (https://github.com/ChiChou/bagbak)
#   * frida-ios-dump (https://github.com/AloneMonkey/frida-ios-dump)
#   * usbmuxd (brew install usbmuxd) + iproxy started with 'iproxy 2222 22'

defaultCountry="US"
country=$2
appUrl=$1
if [ "${appUrl}" == "--help" ] || [ "${appUrl}" == "-h" ]; then
  echo "Usage: ipa.sh [URL] [COUNTRY]"
  echo "URL - url of the ios app store app, eg. https://apps.apple.com/us/app/discord-talk-chat-hangout/id985746746"
  echo "    Default: none. Will be read from stdin when not provided"
  echo "COUNTRY - optional, capital two-letter country code, eg US = united states. Check https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes"
  echo "    Default: US"
  exit 0
fi
if [ -z "${appUrl}" ]; then
  echo "Provide url, eg https://apps.apple.com/us/app/discord-talk-chat-hangout/id985746746"
  read appUrl
fi
if [ -z "${country}" ]; then
  country=$defaultCountry
fi

parseId=${appUrl/*id/}
parseId=${parseId//[^0-9]/}
idLen=${#parseId}
if [ ${idLen} -lt 9 ] || [ ${idLen} -gt 10 ]; then
  echo "Bad url"
  exit 1
fi

# brew install curl
# brew install jq
appInfo=`curl -s "https://itunes.apple.com/${country}/lookup?id=${parseId}"`
bundleId=`echo ${appInfo}|jq -r '.results[0].bundleId'`
appVersion=`echo ${appInfo}|jq -r '.results[0].version'`
if [ -z "${bundleId}" ]; then
  echo "App doesn't exist or was removed!"
  exit 1
fi

if [ -f ${bundleId}*.ipa ]; then
  echo ".ipa File present, skipping download"
else
  echo ".ipa File does not exist, downloading"
  # brew tap majd/repo; brew install ipatool
  ipatool download --purchase -c $country -b $bundleId
  result=$?
  if [ $result -ne 0 ]; then
    echo "Purchase or download failed! please login with 'ipatool auth login'"
    echo "Please use country your appleid is in, eg. US for united states or AU for australia"
    echo "check https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes"
    exit 1
  fi
fi
fileName=`echo ${bundleId}*.ipa`
# brew install ideviceinstaller
appNames=`ideviceinstaller -l |grep ${bundleId}`
result=$?
if [ $result -eq 0 ]; then
  echo "App ${bundleId} installed, skipping to dump"
else
  echo "App ${bundleId} not installed, installing"
  ideviceinstaller -i $fileName
  result=$?
  if [ $result -ne 0 ]; then
    echo "Install failed!"
    exit 1
  fi
  appNames=`ideviceinstaller -l |grep ${bundleId}`
fi
# known as 'bundleDisplayName'
displayId=`echo ${appNames}|awk '{print $3}'`
displayId=${displayId//\"/}
decrFileName="${displayId}_${appVersion}.ipa"
echo "Dumping to ${decrFileName} ..."
# https://github.com/ChiChou/bagbak
bagbak -z ${bundleId}
# when bagbak crashes, result is still 0, but if it fails there is no ipa
if [ -f dump/${bundleId}.ipa ]; then 
  echo "Bagbak success"
  mv dump/${bundleId}.ipa ./${decrFileName}
else
  # fall back to frida
  echo "Bagbak fail, do frida dump"
  echo "Check usb ssh"
  echo|nc 127.0.0.1 2222
  result=$?
  if [ $result -ne 0 ]; then
    echo "No iproxy! please run 'iproxy 2222 22'"
    exit 1
  fi
  # frida-ios-dump
  python3 dump.py ${bundleId} -o ${decrFileName}
  result=$?
  if [ $result -ne 0 ]; then
    echo "Dump failed!"
    exit 1
  fi
fi

echo "File ready! check ${decrFileName}"
echo "Cleaning up..."
ideviceinstaller -U ${bundleId}
rm $fileName
