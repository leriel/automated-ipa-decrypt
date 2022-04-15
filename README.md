# Fully automated ipa decrypt
**Please do not use your main apple id for third party tools**

# Requirements:
* jailbroken ios device (set device screen to sleep 5min/never)
* mac


# Example setup

* ios 14.2 device
  * unc0ver 6.1.2 installed via sideloadly (8.x.x for some reason didn't work on my device)
  * cydia (via unc0ver, make sure to check option)
  * openssh (via cydia)
  * frida (via cydia)

* mac
  * curl, jq (brew install curl jq)
  * ipatool (https://github.com/majd/ipatool/)
  * being logged via ipatool auth login. Need to provide email+password+2fa only first time you login. After that you just login via email+password.
  * device connected via usb and computer trusted by device
  * bagbak (https://github.com/ChiChou/bagbak)
  * frida-ios-dump (https://github.com/AloneMonkey/frida-ios-dump)
  * usbmuxd (brew install usbmuxd) + iproxy started with 'iproxy 2222 22'

# Usage

1. Install and configure necessary tools
* `brew tap majd/repo`
* `brew install curl jq ipatool nodejs python git`
* `npm install -g bagbak`
2. Clone and setup necessary repos
* `git clone https://github.com/AloneMonkey/frida-ios-dump.git ~/work/frida-ios-dump`
* `git clone https://github.com/leriel/automated-ipa-decrypt.git ~/work/automated-ipa-decrypt`
* `cd ~/work/frida-ios-dump`
* `pip install -r requirements.txt`
3. Connect and trust jailbroken device
4. Decrypt from URL and country code. Country code needs to match billing address of your apple id. List of country codes: https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes
* `~/work/automated-ipa-decrypt/ipa.sh https://apps.apple.com/us/app/discord-chat-talk-hangout/id985746746 US`
