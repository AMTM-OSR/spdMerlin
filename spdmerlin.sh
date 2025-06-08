#!/bin/sh

##############################################################
##                    _  __  __              _  _           ##
##                   | ||  \/  |            | |(_)          ##
##    ___  _ __    __| || \  / |  ___  _ __ | | _  _ __     ##
##   / __|| '_ \  / _` || |\/| | / _ \| '__|| || || '_ \    ##
##   \__ \| |_) || (_| || |  | ||  __/| |   | || || | | |   ##
##   |___/| .__/  \__,_||_|  |_| \___||_|   |_||_||_| |_|   ##
##        | |                                               ##
##        |_|                                               ##
##                                                          ##
##         https://github.com/AMTM-OSR/spdMerlin            ##
##     Forked from https://github.com/jackyaz/spdMerlin     ##
##                                                          ##
##############################################################
# Last Modified: 2025-Jun-08
#-------------------------------------------------------------

##############        Shellcheck directives      #############
# shellcheck disable=SC2009
# shellcheck disable=SC2012
# shellcheck disable=SC2016
# shellcheck disable=SC2018
# shellcheck disable=SC2019
# shellcheck disable=SC2028
# shellcheck disable=SC2039
# shellcheck disable=SC2059
# shellcheck disable=SC2086
# shellcheck disable=SC2155
# shellcheck disable=SC2174
# shellcheck disable=SC3018
# shellcheck disable=SC3037
# shellcheck disable=SC3043
# shellcheck disable=SC3045
##############################################################

### Start of script variables ###
readonly SCRIPT_NAME="spdMerlin"
readonly SCRIPT_NAME_LOWER="$(echo "$SCRIPT_NAME" | tr 'A-Z' 'a-z')"
readonly SCRIPT_VERSION="v4.4.10"
readonly SCRIPT_VERSTAG="25060820"
SCRIPT_BRANCH="develop"
SCRIPT_REPO="https://raw.githubusercontent.com/AMTM-OSR/$SCRIPT_NAME/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME_LOWER.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink -f /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME_LOWER"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/AMTM-OSR/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
readonly TEMP_MENU_TREE="/tmp/menuTree.js"

readonly HOME_DIR="/$(readlink "$HOME")"
readonly OOKLA_DIR="$SCRIPT_DIR/ookla"
readonly OOKLA_LICENSE_DIR="$SCRIPT_DIR/ooklalicense"
readonly OOKLA_HOME_DIR="$HOME_DIR/.config/ookla"
readonly FULL_IFACELIST="WAN VPNC1 VPNC2 VPNC3 VPNC4 VPNC5 WGVPN1 WGVPN2 WGVPN3 WGVPN4 WGVPN5"

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
readonly scriptVersRegExp="v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})"
readonly webPageMenuAddons="menuName: \"Addons\","
readonly webPageHelpSupprt="tabName: \"Help & Support\"},"
readonly webPageFileRegExp="user([1-9]|[1-2][0-9])[.]asp"
readonly webPageLineTabExp="\{url: \"$webPageFileRegExp\", tabName: "
readonly webPageLineRegExp="${webPageLineTabExp}\"$SCRIPT_NAME\"\},"
readonly BEGIN_MenuAddOnsTag="/\*\*BEGIN:_AddOns_\*\*/"
readonly ENDIN_MenuAddOnsTag="/\*\*ENDIN:_AddOns_\*\*/"
readonly scriptVERINFO="[${SCRIPT_VERSION}_${SCRIPT_VERSTAG}, Branch: $SCRIPT_BRANCH]"

# For daily CRON job to trim database #
readonly defTrimDB_Hour=3
readonly defTrimDB_Mins=5

readonly oneHrSec=3600
readonly _12Hours=43200
readonly _24Hours=86400
readonly _36Hours=129600
readonly oneKByte=1024
readonly oneMByte=1048576
readonly ei8MByte=8388608
readonly ni9MByte=9437184
readonly tenMByte=10485760
readonly oneGByte=1073741824
readonly SHARE_TEMP_DIR="/opt/share/tmp"

##-------------------------------------##
## Added by Martinski W. [2025-Jun-04] ##
##-------------------------------------##
readonly sqlDBLogFileSize=102400
readonly sqlDBLogDateTime="%Y-%m-%d %H:%M:%S"
readonly sqlDBLogFileName="${SCRIPT_NAME}_DBSQL_DEBUG.LOG"

# Give priority to built-in binaries #
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:$PATH"

[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL="$(nvram get productid)" || ROUTER_MODEL="$(nvram get odmpid)"
[ -f /opt/bin/sqlite3 ] && SQLITE3_PATH=/opt/bin/sqlite3 || SQLITE3_PATH=/usr/sbin/sqlite3

if [ "$(uname -m)" = "aarch64" ]; then
	ARCH="aarch64"
else
	/bin/grep -Eq 'Features\s*:.*\s+v?fp\s+' /proc/cpuinfo && ARCH="arm" || ARCH="armel"
fi
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
readonly BOLD="\\e[1m"
readonly SETTING="${BOLD}\\e[36m"
readonly CLEARFORMAT="\\e[0m"

##-------------------------------------##
## Added by Martinski W. [2025-Feb-15] ##
##-------------------------------------##
readonly CLRct="\e[0m"
readonly REDct="\e[1;31m"
readonly GRNct="\e[1;32m"
readonly CritIREDct="\e[41m"
readonly CritBREDct="\e[30;101m"
readonly PassBGRNct="\e[30;102m"
readonly WarnBYLWct="\e[30;103m"
readonly WarnIMGNct="\e[45m"
readonly WarnBMGNct="\e[30;105m"

### End of output format variables ###

### Start of Speedtest Server Variables ###
serverno=""
servername=""
### End of Speedtest Server Variables ###

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output()
{
	local prioStr  prioNum
	if [ $# -gt 2 ] && [ -n "$3" ]
	then prioStr="$3"
	else prioStr="NOTICE"
	fi
	if [ "$1" = "true" ]
	then
		case "$prioStr" in
		    "$CRIT") prioNum=2 ;;
		     "$ERR") prioNum=3 ;;
		    "$WARN") prioNum=4 ;;
		    "$PASS") prioNum=6 ;; #INFO#
		          *) prioNum=5 ;; #NOTICE#
		esac
		logger -t "$SCRIPT_NAME" -p $prioNum "$2"
	fi
	printf "${BOLD}${3}%s${CLEARFORMAT}\n\n" "$2"
}

Firmware_Version_Check()
{
	if nvram get rc_support | grep -qF "am_addons"; then
		return 0
	else
		return 1
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock()
{
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]
	then
		ageoflock="$(($(/bin/date "+%s") - $(/bin/date "+%s" -r "/tmp/$SCRIPT_NAME.lock")))"
		if [ "$ageoflock" -gt 600 ]  #10 minutes#
		then
			Print_Output true "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' "/tmp/$SCRIPT_NAME.lock")" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output true "Lock file found (age: $ageoflock seconds) - stopping to prevent duplicate runs" "$ERR"
			if [ $# -eq 0 ] || [ -z "$1" ]
			then
				exit 1
			else
				if [ "$1" = "webui" ]; then
					echo 'var spdteststatus = "LOCKED";' > /tmp/detect_spdtest.js
					exit 1
				fi
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME.lock"
		return 0
	fi
}

Clear_Lock()
{
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}

Check_Swap(){
	if [ "$(wc -l < /proc/swaps)" -ge 2 ]; then return 0; else return 1; fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-02] ##
##----------------------------------------##
Set_Version_Custom_Settings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]
			then
				if [ "$(grep -c "^spdmerlin_version_local" "$SETTINGSFILE")" -gt 0 ]
				then
					if [ "$2" != "$(grep "^spdmerlin_version_local" "$SETTINGSFILE" | cut -f2 -d' ')" ]
					then
						sed -i "s/^spdmerlin_version_local.*/spdmerlin_version_local $2/" "$SETTINGSFILE"
					fi
				else
					echo "spdmerlin_version_local $2" >> "$SETTINGSFILE"
				fi
			else
				echo "spdmerlin_version_local $2" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]
			then
				if [ "$(grep -c "^spdmerlin_version_server" "$SETTINGSFILE")" -gt 0 ]
				then
					if [ "$2" != "$(grep "^spdmerlin_version_server" "$SETTINGSFILE" | cut -f2 -d' ')" ]
					then
						sed -i "s/^spdmerlin_version_server.*/spdmerlin_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "spdmerlin_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "spdmerlin_version_server $2" >> "$SETTINGSFILE"
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
Update_Check()
{
	echo 'var updatestatus = "InProgress";' > "$SCRIPT_WEB_DIR/detect_update.js"
	doupdate="false"
	localver="$(grep "SCRIPT_VERSION=" "/jffs/scripts/$SCRIPT_NAME_LOWER" | grep -m1 -oE "$scriptVersRegExp")"
	[ -n "$localver" ] && Set_Version_Custom_Settings local "$localver"
	curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | grep -qF "jackyaz" || \
    { Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE "$scriptVersRegExp")"
	if [ "$localver" != "$serverver" ]
	then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME_LOWER" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]
		then
			doupdate="md5"
			Set_Version_Custom_Settings server "$serverver-hotfix"
			echo 'var updatestatus = "'"$serverver-hotfix"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		fi
	fi
	if [ "$doupdate" = "false" ]; then
		echo 'var updatestatus = "None";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	fi
	echo "$doupdate,$localver,$serverver"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
Update_Version()
{
	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"
		
		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - hotfix available - $serverver" "$PASS"
		fi
		
		if [ "$isupdate" != "false" ]
		then
			printf "\n${BOLD}Do you want to continue with the update? (y/n)${CLEARFORMAT}  "
			read -r confirm
			case "$confirm" in
				y|Y)
					printf "\n"
					Update_File README.md
					Update_File LICENSE
					Update_File "$ARCH.tar.gz"
					Update_File spdstats_www.asp
					Update_File shared-jy.tar.gz
					Download_File "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" "/jffs/scripts/$SCRIPT_NAME_LOWER" && \
					Print_Output true "$SCRIPT_NAME successfully updated" "$PASS"
					chmod 0755 "/jffs/scripts/$SCRIPT_NAME_LOWER"
					Set_Version_Custom_Settings local "$serverver"
					Set_Version_Custom_Settings server "$serverver"
					Clear_Lock
					PressEnter
					exec "$0"
					exit 0
				;;
				*)
					printf "\n"
					Clear_Lock
					return 1
				;;
			esac
					
		else
			Print_Output true "No updates available - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi

	if [ "$1" = "force" ]
	then
		serverver="$(curl -fsL --retry 4 --retry-delay 5 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE "$scriptVersRegExp")"
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File README.md
		Update_File LICENSE
		Update_File "$ARCH.tar.gz"
		Update_File spdstats_www.asp
		Update_File shared-jy.tar.gz
		Download_File "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" "/jffs/scripts/$SCRIPT_NAME_LOWER" && \
		Print_Output true "$SCRIPT_NAME successfully updated" "$PASS"
		chmod 0755 "/jffs/scripts/$SCRIPT_NAME_LOWER"
		Set_Version_Custom_Settings local "$serverver"
		Set_Version_Custom_Settings server "$serverver"
		Clear_Lock
		if [ $# -lt 2 ] || [ -z "$2" ]
		then
			PressEnter
			exec "$0"
		elif [ "$2" = "unattended" ]
		then
			exec "$0" postupdate
		fi
		exit 0
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-15] ##
##----------------------------------------##
Update_File()
{
	if [ "$1" = "$ARCH.tar.gz" ]
	then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		tar -xzf "$tmpfile" -C "/tmp"
		rm -f "$tmpfile"
		localmd5="$(md5sum "$OOKLA_DIR/speedtest" | awk '{print $1}')"
		tmpmd5="$(md5sum /tmp/speedtest | awk '{print $1}')"
		if [ "$localmd5" != "$tmpmd5" ]
		then
			rm -f "$OOKLA_DIR"/*
			Download_File "$SCRIPT_REPO/$1" "$OOKLA_DIR/$1"
			tar -xzf "$OOKLA_DIR/$1" -C "$OOKLA_DIR"
			rm -f "$OOKLA_DIR/$1"
			chmod 0755 "$OOKLA_DIR/speedtest"
			Print_Output true "New version of Speedtest CLI downloaded to $OOKLA_DIR/speedtest" "$PASS"
		fi
		rm -f /tmp/speedtest*
	elif [ "$1" = "spdstats_www.asp" ]
	then
		tmpfile="/tmp/$1"
		if [ -f "$SCRIPT_DIR/$1" ]
		then
			Download_File "$SCRIPT_REPO/$1" "$tmpfile"
			if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1
			then
				Get_WebUI_Page "$SCRIPT_DIR/$1"
				sed -i "\\~$MyWebPage~d" "$TEMP_MENU_TREE"
				rm -f "$SCRIPT_WEBPAGE_DIR/$MyWebPage" 2>/dev/null
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
				Mount_WebUI
			fi
			rm -f "$tmpfile"
		else
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
	elif [ "$1" = "shared-jy.tar.gz" ]
	then
		if [ ! -f "$SHARED_DIR/${1}.md5" ]
		then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/${1}.md5" "$SHARED_DIR/${1}.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/${1}.md5")"
			remotemd5="$(curl -fsL --retry 4 --retry-delay 5 "$SHARED_REPO/${1}.md5")"
			if [ "$localmd5" != "$remotemd5" ]
			then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/${1}.md5" "$SHARED_DIR/${1}.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	elif [ "$1" = "README.md" ] || [ "$1" = "LICENSE" ]
	then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
		fi
		rm -f "$tmpfile"
	else
		return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-12] ##
##----------------------------------------##
Validate_Bandwidth()
{
	if echo "$1" | grep -oqE "^([0-9]+([.][0-9]*)?|[0-9]*[.][0-9]+)$"
	then return 0
	else return 1
	fi
}

Validate_Number()
{
	if [ "$1" -eq "$1" ] 2>/dev/null
	then return 0
	else return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
Create_Dirs()
{
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$SCRIPT_STORAGE_DIR" ]; then
		mkdir -p "$SCRIPT_STORAGE_DIR"
	fi
	
	if [ ! -d "$CSV_OUTPUT_DIR" ]; then
		mkdir -p "$CSV_OUTPUT_DIR"
	fi
	
	if [ ! -d "$OOKLA_DIR" ]; then
		mkdir -p "$OOKLA_DIR"
	fi
	
	if [ ! -d "$OOKLA_LICENSE_DIR" ]; then
		mkdir -p "$OOKLA_LICENSE_DIR"
	fi
	
	if [ ! -d "$OOKLA_HOME_DIR" ]; then
		mkdir -p "$OOKLA_HOME_DIR"
	fi
	
	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEBPAGE_DIR" ]; then
		mkdir -p "$SCRIPT_WEBPAGE_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi

	if [ ! -d "$SHARE_TEMP_DIR" ]
	then
		mkdir -m 777 -p "$SHARE_TEMP_DIR"
		export SQLITE_TMPDIR TMPDIR
	fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Mar-08] ##
##-------------------------------------##
## For both OpenVPN and WAN interfaces ##
##-------------------------------------##
_CheckNetClientInterfaceUP_()
{
   if [ $# -eq 0 ] || [ -z "$1" ] ; then return 1 ; fi

   local IFACE_NAME="$1"

   if echo "$1" | grep -qE "^[1-5]$"
   then IFACE_NAME="tun1$1" ; fi

   if [ ! -f "/sys/class/net/${IFACE_NAME}/operstate" ] || \
      [ "$(cat "/sys/class/net/${IFACE_NAME}/operstate")" = "down" ]
   then return 1
   else return 0
   fi
}

##############################################################
# Checks if 'wgcX' interface is enabled in NVRAM *AND*
# verifies that it had a handshake within THRESHOLD seconds.
# Returns 0 if "connected" (up), 1 otherwise (down).
#-------------------------------------------------------------
# Modified by Martinski W. [2025-Mar-08]
##############################################################
_Check_WG_ClientInterfaceUP_()
{
    if [ $# -eq 0 ] || [ -z "$1" ] ; then return 1 ; fi
    local IFACE_NAME  threshold  handshakeLine

    if echo "$1" | grep -qE "^wgc[1-5]$"
    then IFACE_NAME="$1"
    else IFACE_NAME="wgc$1"
    fi

	threshold=180  # 180-second cutoff for "connected" #

	# First confirm NVRAM says it is enabled #
	# wgc1_enable = 1 => on, 0 => off #
	if [ "$(nvram get ${IFACE_NAME}_enable)" != "1" ]
	then  # NOT enabled #
	    return 1
	fi

	# Attempt to read the handshake time from 'wg' #
	# If no handshake line, consider it "down" #
	handshakeLine="$(wg show "$IFACE_NAME" latest-handshakes 2>/dev/null | head -n1)"
	[ -z "$handshakeLine" ] && return 1

	# Extract numeric epoch from the second column #
	timestamp="$(echo "$handshakeLine" | awk '{print $2}')"
	# If no timestamp or if it’s explicitly zero, treat as "disconnected" #
	if [ -z "$timestamp" ] || [ "$timestamp" = "0" ]
	then
	    return 1
	fi

	# Compare to current time #
	nowtime="$(date +%s)"
	elapsed="$((nowtime - timestamp))"

	# If handshake was within threshold, call it "up" #
	if [ "$elapsed" -ge 0 ] && [ "$elapsed" -le "$threshold" ]
	then
	    return 0
	fi

  	# Otherwise, treat as "down" #
	return 1
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-08] ##
##----------------------------------------##
Create_Symlinks()
{
	printf "WAN\n" > "$SCRIPT_INTERFACES"

    local ifaceTagStr
    local excludedNotUPstr=" #excluded - interface not up#"

	for index in 1 2 3 4 5
	do
        ifaceTagStr="$excludedNotUPstr"
		if _CheckNetClientInterfaceUP_ "$index"
		then
			ifaceTagStr=""  #Interface is included#
		fi
		printf "VPNC%s%s\n" "$index" "$ifaceTagStr" >> "$SCRIPT_INTERFACES"
	done

	for index in 1 2 3 4 5
	do
		ifaceTagStr="$excludedNotUPstr"
		if _Check_WG_ClientInterfaceUP_ "$index"
		then
			ifaceTagStr=""  #Interface is included#
		fi
		printf "WGVPN%s%s\n" "$index" "$ifaceTagStr" >> "$SCRIPT_INTERFACES"
	done

	if [ $# -gt 0 ] && [ "$1" = "force" ]; then
		rm -f "$SCRIPT_INTERFACES_USER"
	fi

	if [ ! -f "$SCRIPT_INTERFACES_USER" ]; then
		touch "$SCRIPT_INTERFACES_USER"
	fi

	while IFS='' read -r line || [ -n "$line" ]
	do
		if [ "$(grep -c "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')" "$SCRIPT_INTERFACES_USER")" -eq 0 ]
		then
			printf "%s\n" "$line" >> "$SCRIPT_INTERFACES_USER"
		fi
	done < "$SCRIPT_INTERFACES"

	interfaceCount="$(wc -l < "$SCRIPT_INTERFACES_USER")"
	COUNTER=1
	until [ "$COUNTER" -gt "$interfaceCount" ]
	do
		Set_Interface_State "$COUNTER"
		COUNTER="$((COUNTER + 1))"
	done

	rm -rf "${SCRIPT_WEB_DIR:?}/"* 2>/dev/null

	ln -s /tmp/spd-stats.txt "$SCRIPT_WEB_DIR/spd-stats.htm" 2>/dev/null
	ln -s /tmp/spd-result.txt "$SCRIPT_WEB_DIR/spd-result.htm" 2>/dev/null
	ln -s /tmp/detect_spdtest.js "$SCRIPT_WEB_DIR/detect_spdtest.js" 2>/dev/null
	ln -s /tmp/spdmerlin-binary "$SCRIPT_WEB_DIR/spd-binary.htm" 2>/dev/null
	ln -s "$SCRIPT_STORAGE_DIR/.autobwoutfile" "$SCRIPT_WEB_DIR/autobwoutfile.htm" 2>/dev/null

	ln -s "$SCRIPT_CONF" "$SCRIPT_WEB_DIR/config.htm" 2>/dev/null
	ln -s "$SCRIPT_INTERFACES_USER"  "$SCRIPT_WEB_DIR/interfaces_user.htm" 2>/dev/null
	ln -s "$SCRIPT_STORAGE_DIR/spdtitletext.js" "$SCRIPT_WEB_DIR/spdtitletext.js" 2>/dev/null

	for IFACE_NAME in $FULL_IFACELIST
	do
		ln -s "$SCRIPT_STORAGE_DIR/lastx_${IFACE_NAME}.csv" "$SCRIPT_WEB_DIR/lastx_${IFACE_NAME}.htm"
	done

	ln -s "$CSV_OUTPUT_DIR" "$SCRIPT_WEB_DIR/csv" 2>/dev/null

	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-19] ##
##----------------------------------------##
Conf_FromSettings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	TMPFILE="/tmp/spdmerlin_settings.txt"

	if [ -f "$SETTINGSFILE" ]
	then
		if [ "$(grep "^spdmerlin_" $SETTINGSFILE | grep -v "version" -c)" -gt 0 ]
		then
			Print_Output true "Updated settings from WebUI found, merging into $SCRIPT_CONF" "$PASS"
			cp -a "$SCRIPT_CONF" "${SCRIPT_CONF}.bak"
			grep "^spdmerlin_" "$SETTINGSFILE" | grep -v "version" > "$TMPFILE"
			sed -i "s/^spdmerlin_//g;s/ /=/g" "$TMPFILE"
			while IFS='' read -r line || [ -n "$line" ]
			do
				SETTINGNAME="$(echo "$line" | cut -f1 -d'=' | awk '{print toupper($1)}')"
				SETTINGVALUE="$(echo "$line" | cut -f2- -d'=' | sed "s/=/ /g")"
				sed -i "s~$SETTINGNAME=.*~$SETTINGNAME=$SETTINGVALUE~" "$SCRIPT_CONF"
			done < "$TMPFILE"

			grep '^spdmerlin_version' "$SETTINGSFILE" > "$TMPFILE"
			sed -i "\\~spdmerlin_~d" "$SETTINGSFILE"
			mv -f "$SETTINGSFILE" "${SETTINGSFILE}.bak"
			cat "${SETTINGSFILE}.bak" "$TMPFILE" > "$SETTINGSFILE"
			rm -f "$TMPFILE"
			rm -f "${SETTINGSFILE}.bak"

			if diff "$SCRIPT_CONF" "${SCRIPT_CONF}.bak" | grep -q "STORAGELOCATION="
			then
				STORAGEtype="$(ScriptStorageLocation check)"
				if [ "$STORAGEtype" = "jffs" ]
				then
				    ## Check if enough free space is available in JFFS ##
				    if _Check_JFFS_SpaceAvailable_ "$SCRIPT_STORAGE_DIR"
				    then ScriptStorageLocation jffs
				    else ScriptStorageLocation usb
				    fi
				elif [ "$STORAGEtype" = "usb" ]
				then
				    ScriptStorageLocation usb
				fi
				Create_Symlinks
			fi
			if diff "$SCRIPT_CONF" "${SCRIPT_CONF}.bak" | grep -qE "(SCHDAYS|SCHHOUR|SCHMINS|AUTOMATICMODE=)"
			then
				Auto_Cron delete 2>/dev/null
				AutomaticMode check && Auto_Cron create 2>/dev/null
			fi
			if [ "$(AutoBWEnable check)" = "true" ]
			then
				if [ "$(ExcludeFromQoS check)" = "false" ]; then
					Print_Output true "Enabling Exclude from QoS (required for AutoBW)"
					ExcludeFromQoS enable
				fi
			fi
			if diff "$SCRIPT_CONF" "${SCRIPT_CONF}.bak" | grep -qE "(STORERESULTURL=|OUTPUTTIMEMODE=|DAYSTOKEEP=|LASTXRESULTS=)"
			then
				Generate_CSVs
			fi
			Print_Output true "Merge of updated settings from WebUI completed successfully" "$PASS"
		else
			Print_Output true "No updated settings from WebUI found, no merge into $SCRIPT_CONF necessary" "$PASS"
		fi
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-08] ##
##----------------------------------------##
Interfaces_FromSettings()
{
	SETTINGSFILE="/jffs/addons/custom_settings.txt"

	local ifaceTagStr  interface_UP
	local excludedNotUPstr=" #excluded - interface not up#"

	if [ -f "$SETTINGSFILE" ]
	then
		if grep -q "spdmerlin_ifaces_enabled" "$SETTINGSFILE"
		then
			Print_Output true "Updated interfaces from WebUI found, merging into $SCRIPT_INTERFACES_USER" "$PASS"
			cp -a "$SCRIPT_INTERFACES_USER" "${SCRIPT_INTERFACES_USER}.bak"
			SETTINGVALUE="$(grep "spdmerlin_ifaces_enabled" "$SETTINGSFILE" | cut -f2 -d' ')"
			sed -i "\\~spdmerlin_ifaces_enabled~d" "$SETTINGSFILE"

			printf "WAN #excluded#\n" > "$SCRIPT_INTERFACES"

			for index in 1 2 3 4 5
			do
				ifaceTagStr="$excludedNotUPstr"
				if _CheckNetClientInterfaceUP_ "$index"
				then
				    ifaceTagStr=" #excluded#"
				fi
				printf "VPNC%s%s\n" "$index" "$ifaceTagStr" >> "$SCRIPT_INTERFACES"
			done

			for index in 1 2 3 4 5
			do
				ifaceTagStr="$excludedNotUPstr"
				if _Check_WG_ClientInterfaceUP_ "$index"
				then
				    ifaceTagStr=" #excluded#"
				fi
				printf "WGVPN%s%s\n" "$index" "$ifaceTagStr" >> "$SCRIPT_INTERFACES"
			done

			echo "" > "$SCRIPT_INTERFACES_USER"

			while IFS='' read -r line || [ -n "$line" ]
			do
				if [ "$(grep -c "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')" "$SCRIPT_INTERFACES_USER")" -eq 0 ]
				then
					printf "%s\n" "$line" >> "$SCRIPT_INTERFACES_USER"
				fi
			done < "$SCRIPT_INTERFACES"

			interfaceCount="$(wc -l < "$SCRIPT_INTERFACES_USER")"
			COUNTER=1
			until [ "$COUNTER" -gt "$interfaceCount" ]
			do
				Set_Interface_State "$COUNTER"
				COUNTER="$((COUNTER + 1))"
			done

			for IFACEname in $(echo "$SETTINGVALUE" | sed "s/,/ /g")
			do
				ifacelinenumber="$(grep -n "$IFACEname" "$SCRIPT_INTERFACES_USER" | cut -f1 -d':')"
				interfaceLine="$(sed "$ifacelinenumber!d" "$SCRIPT_INTERFACES_USER" | awk '{$1=$1};1')"
				IFACE_NAME="$(echo "$interfaceLine" | cut -f1 -d"#" | sed 's/ *$//')"
				IFACE_LOWER="$(Get_Interface_From_Name "$IFACE_NAME" | tr 'A-Z' 'a-z')"

				interface_UP=false
				if echo "$IFACE_NAME" | grep -q "^WGVPN"
				then
				    if _Check_WG_ClientInterfaceUP_ "$IFACE_LOWER"
				    then interface_UP=true ; fi
				else
				    if _CheckNetClientInterfaceUP_ "$IFACE_LOWER"
				    then interface_UP=true ; fi
				fi

				if echo "$interfaceLine" | grep -q "#excluded"
				then
					if "$interface_UP"
					then
						sed -i "${ifacelinenumber}s/ #excluded - interface not up#//" "$SCRIPT_INTERFACES_USER"
						sed -i "${ifacelinenumber}s/ #excluded#//" "$SCRIPT_INTERFACES_USER"
					else
						sed -i "${ifacelinenumber}s/ #excluded#/ #excluded - interface not up#/" "$SCRIPT_INTERFACES_USER"
					fi
				else
					if ! "$interface_UP"
					then
						sed -i "$ifacelinenumber"'s/$/ #excluded - interface not up#/' "$SCRIPT_INTERFACES_USER"
					fi
				fi
			done

			awk 'NF' "$SCRIPT_INTERFACES_USER" > /tmp/spd-interfaces
			mv -f /tmp/spd-interfaces "$SCRIPT_INTERFACES_USER"

			Print_Output true "Merge of updated interfaces from WebUI completed successfully" "$PASS"
		else
			Print_Output true "No updated interfaces from WebUI found, no merge into $SCRIPT_INTERFACES_USER necessary" "$PASS"
		fi
	fi
}

##-------------------------------------##
## Added by Martinski W. [2024-Nov-15] ##
##-------------------------------------##
_GetDefaultSpeedTestBinary_()
{
   if [ -f /usr/sbin/ookla ]
   then echo "builtin"
   else echo "external"
   fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Jun-06] ##
##-------------------------------------##
_GetConfigParam_()
{
   if [ $# -eq 0 ] || [ -z "$1" ]
   then echo '' ; return 1 ; fi

   local keyValue  checkFile
   local defValue="$([ $# -eq 2 ] && echo "$2" || echo '')"

   if [ ! -s "$SCRIPT_CONF" ]
   then echo "$defValue" ; return 0 ; fi

   if [ "$(grep -c "^${1}=" "$SCRIPT_CONF")" -gt 1 ]
   then  ## Remove duplicates. Keep ONLY the 1st key ##
       checkFile="${SCRIPT_CONF}.DUPKEY.txt"
       awk "!(/^${1}=/ && dup[/^${1}=/]++)" "$SCRIPT_CONF" > "$checkFile"
       if diff -q "$checkFile" "$SCRIPT_CONF" >/dev/null 2>&1
       then rm -f "$checkFile"
       else mv -f "$checkFile" "$SCRIPT_CONF"
       fi
   fi

   keyValue="$(grep "^${1}=" "$SCRIPT_CONF" | cut -d'=' -f2)"
   echo "${keyValue:=$defValue}"
   return 0
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-14] ##
##----------------------------------------##
Conf_Exists()
{
	local AUTOMATEDopt

	if [ -f "$SCRIPT_CONF" ]
	then
		dos2unix "$SCRIPT_CONF"
		chmod 0644 "$SCRIPT_CONF"
		sed -i -e 's/"//g' "$SCRIPT_CONF"
		if grep -q "^AUTOMATED=.*" "$SCRIPT_CONF"
		then
			AUTOMATEDopt="$(grep "^AUTOMATED=" "$SCRIPT_CONF" | cut -f2 -d'=')"
			sed -i 's/^AUTOMATED=.*$/AUTOMATICMODE='"$AUTOMATEDopt"'/' "$SCRIPT_CONF"
		fi
		if ! grep -q "^AUTOMATICMODE=" "$SCRIPT_CONF"; then
			echo "AUTOMATICMODE=true" >> "$SCRIPT_CONF"
		fi
		if grep -q "SCHEDULESTART" "$SCRIPT_CONF"
		then
			{
			  echo "SCHDAYS=*";
			  echo "SCHHOURS=*";
			  echo "SCHMINS=12,42";
			} >> "$SCRIPT_CONF"
			sed -i '/SCHEDULESTART/d;/SCHEDULEEND/d;/MINUTE/d;/TESTFREQUENCY/d' "$SCRIPT_CONF"
			Auto_Cron delete 2>/dev/null
		fi
		if ! grep -q "^AUTOBW_AVERAGE_CALC=" "$SCRIPT_CONF"; then
			echo "AUTOBW_AVERAGE_CALC=10" >> "$SCRIPT_CONF"
		fi
		if grep -q "OUTPUTDATAMODE" "$SCRIPT_CONF"; then
			sed -i '/OUTPUTDATAMODE/d;' "$SCRIPT_CONF"
		fi
		if ! grep -q "^OUTPUTTIMEMODE=" "$SCRIPT_CONF"; then
			echo "OUTPUTTIMEMODE=unix" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^DAYSTOKEEP=" "$SCRIPT_CONF"; then
			echo "DAYSTOKEEP=30" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^LASTXRESULTS=" "$SCRIPT_CONF"; then
			echo "LASTXRESULTS=10" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^STORAGELOCATION=" "$SCRIPT_CONF"; then
			echo "STORAGELOCATION=jffs" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^JFFS_MSGLOGTIME=" "$SCRIPT_CONF"; then
			echo "JFFS_MSGLOGTIME=0" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^VERBOSE_TEST=" "$SCRIPT_CONF"; then
			echo "VERBOSE_TEST=0" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^EXCLUDEFROMQOS=" "$SCRIPT_CONF"; then
			echo "EXCLUDEFROMQOS=true" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^SPEEDTESTBINARY=" "$SCRIPT_CONF"
		then
			echo "SPEEDTESTBINARY=$(_GetDefaultSpeedTestBinary_)" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^USEPREFERRED_WAN=" "$SCRIPT_CONF"; then
			echo "USEPREFERRED_WAN=false" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^PREFERREDSERVER_WAN=" "$SCRIPT_CONF"; then
			echo "PREFERREDSERVER_WAN=0|None configured" >> "$SCRIPT_CONF"
		fi
		if ! grep -q "^PREFERREDSERVER_WGVPN" "$SCRIPT_CONF"
		then
			for index in 1 2 3 4 5
			do
			   {
			     echo "USEPREFERRED_WGVPN$index=false";
			     echo "PREFERREDSERVER_WGVPN$index=0|None configured"
			   } >> "$SCRIPT_CONF"
			done
		fi
		return 0
	else
		{
		  echo "PREFERREDSERVER_WAN=0|None configured"
		  echo "USEPREFERRED_WAN=false"; echo "AUTOMATICMODE=true"
		  echo "OUTPUTTIMEMODE=unix"; echo "STORAGELOCATION=jffs"
		  echo "SCHDAYS=*" ; echo "SCHHOURS=*" ; echo "SCHMINS=12,42"
		  echo "DAYSTOKEEP=30" ; echo "LASTXRESULTS=10" ; echo "EXCLUDEFROMQOS=true"
		  echo "JFFS_MSGLOGTIME=0" ; echo "VERBOSE_TEST=0"
		} > "$SCRIPT_CONF"
		for index in 1 2 3 4 5
		do
		   {
		     echo "USEPREFERRED_VPNC${index}=false"
		     echo "PREFERREDSERVER_VPNC${index}=0|None configured"
		   } >> "$SCRIPT_CONF"
		done
		for index in 1 2 3 4 5
		do
		   {
		     echo "USEPREFERRED_WGVPN$index=false"
		     echo "PREFERREDSERVER_WGVPN$index=0|None configured";
		   } >> "$SCRIPT_CONF"
		done
		{
		  echo "AUTOBW_ENABLED=false"
		  echo "AUTOBW_SF_DOWN=95" ; echo "AUTOBW_SF_UP=95"
		  echo "AUTOBW_ULIMIT_DOWN=0" ; echo "AUTOBW_LLIMIT_DOWN=0"
		  echo "AUTOBW_ULIMIT_UP=0" ; echo "AUTOBW_LLIMIT_UP=0"
		  echo "AUTOBW_THRESHOLD_UP=10" ; echo "AUTOBW_THRESHOLD_DOWN=10"
		  echo "AUTOBW_AVERAGE_CALC=10" ; echo "STORERESULTURL=true"
		} >> "$SCRIPT_CONF"
		echo "SPEEDTESTBINARY=$(_GetDefaultSpeedTestBinary_)" >> "$SCRIPT_CONF"
		return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-19] ##
##----------------------------------------##
Auto_ServiceEvent()
{
	local theScriptFilePath="/jffs/scripts/$SCRIPT_NAME_LOWER"
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)"
				STARTUPLINECOUNTEX="$(grep -cx 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME_LOWER"'"; then { '"$theScriptFilePath"' service_event "$@" & }; fi # '"$SCRIPT_NAME" /jffs/scripts/service-event)"

				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ] ; }
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]
				then
					{
					  echo 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME_LOWER"'"; then { '"$theScriptFilePath"' service_event "$@" & }; fi # '"$SCRIPT_NAME"
					} >> /jffs/scripts/service-event
				fi
			else
				{
				  echo "#!/bin/sh" ; echo
				  echo 'if echo "$2" | /bin/grep -q "'"$SCRIPT_NAME_LOWER"'"; then { '"$theScriptFilePath"' service_event "$@" & }; fi # '"$SCRIPT_NAME"
				  echo
				} > /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-19] ##
##----------------------------------------##
Auto_Startup()
{
	local theScriptFilePath="/jffs/scripts/$SCRIPT_NAME_LOWER"
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)"
				STARTUPLINECOUNTEX="$(grep -cx '\[ -x "${1}/entware/bin/opkg" \] && \[ -x '"$theScriptFilePath"' \] && '"$theScriptFilePath"' startup "$@" & # '"$SCRIPT_NAME" /jffs/scripts/post-mount)"

				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ] ; }
				then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
					STARTUPLINECOUNT=0
				fi
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]
				then
					{
					  echo '[ -x "${1}/entware/bin/opkg" ] && [ -x '"$theScriptFilePath"' ] && '"$theScriptFilePath"' startup "$@" & # '"$SCRIPT_NAME"
					} >> /jffs/scripts/post-mount
				fi
			else
				{
				  echo "#!/bin/sh" ; echo
				  echo '[ -x "${1}/entware/bin/opkg" ] && [ -x '"$theScriptFilePath"' ] && '"$theScriptFilePath"' startup "$@" & # '"$SCRIPT_NAME"
				  echo
				} > /jffs/scripts/post-mount
				chmod 0755 /jffs/scripts/post-mount
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]
			then
				STARTUPLINECOUNT="$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)"
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
Auto_Cron()
{
	local theScriptFilePath="/jffs/scripts/$SCRIPT_NAME_LOWER"
	case $1 in
		create)
			STARTUPLINECOUNT="$(cru l | grep -c "#${SCRIPT_NAME}#")"
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "${SCRIPT_NAME}"
			fi
			STARTUPLINECOUNTGEN="$(cru l | grep -c "${SCRIPT_NAME}_generate")"
			CRU_SCHHOUR="$(_GetConfigParam_ SCHHOURS '*')"
			CRU_SCHMINS="$(_GetConfigParam_ SCHMINS '12,42')"
			STARTUPLINECOUNTEXGEN="$(cru l | grep "${SCRIPT_NAME}_generate" | grep -c "^$CRU_SCHMINS $CRU_SCHHOUR [*] [*]")"
			if [ "$STARTUPLINECOUNTGEN" -gt 0 ] && [ "$STARTUPLINECOUNTEXGEN" -eq 0 ]
			then
				cru d "${SCRIPT_NAME}_generate"
				STARTUPLINECOUNTGEN="$(cru l | grep -c "${SCRIPT_NAME}_generate")"
			fi
			if [ "$STARTUPLINECOUNTGEN" -eq 0 ]
			then
				CRU_SCHDAYS="$(_GetConfigParam_ SCHDAYS '*' | sed 's/Sun/0/;s/Mon/1/;s/Tues/2/;s/Wed/3/;s/Thurs/4/;s/Fri/5/;s/Sat/6/;')"
				cru a "${SCRIPT_NAME}_generate" "$CRU_SCHMINS $CRU_SCHHOUR * * $CRU_SCHDAYS $theScriptFilePath generate"
			fi

			STARTUPLINECOUNTTRIM="$(cru l | grep -c "${SCRIPT_NAME}_trimDB")"
			STARTUPLINECOUNTEXTRIM="$(cru l | grep "${SCRIPT_NAME}_trimDB" | grep -c "^$defTrimDB_Mins $defTrimDB_Hour [*] [*]")"
			if [ "$STARTUPLINECOUNTTRIM" -gt 0 ] && [ "$STARTUPLINECOUNTEXTRIM" -eq 0 ]
			then
				cru d "${SCRIPT_NAME}_trimDB"
				STARTUPLINECOUNTTRIM="$(cru l | grep -c "${SCRIPT_NAME}_trimDB")"
			fi
			if [ "$STARTUPLINECOUNTTRIM" -eq 0 ]; then
				cru a "${SCRIPT_NAME}_trimDB" "$defTrimDB_Mins $defTrimDB_Hour * * * $theScriptFilePath trimdb"
			fi
		;;
		delete)
			STARTUPLINECOUNT="$(cru l | grep -c "#${SCRIPT_NAME}#")"
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
			STARTUPLINECOUNTGEN="$(cru l | grep -c "#${SCRIPT_NAME}_generate#")"
			if [ "$STARTUPLINECOUNTGEN" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_generate"
			fi
			STARTUPLINECOUNTTRIM="$(cru l | grep -c "#${SCRIPT_NAME}_trimDB#")"
			if [ "$STARTUPLINECOUNTTRIM" -gt 0 ]; then
				cru d "${SCRIPT_NAME}_trimDB"
			fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-08] ##
##----------------------------------------##
Get_Interface_From_Name()
{
	local IFACEname=""
	case "$1" in
		WAN)
			if [ "$(nvram get sw_mode)" -ne 1 ]
			then
				IFACEname="br0"
			elif [ "$(nvram get wan0_proto)" = "pppoe" ] || \
			     [ "$(nvram get wan0_proto)" = "pptp" ] || \
			     [ "$(nvram get wan0_proto)" = "l2tp" ]
			then
				IFACEname="ppp0"
			else
				IFACEname="$(nvram get wan0_ifname)"
			fi
		;;
		VPNC1) IFACEname="tun11" ;;
		VPNC2) IFACEname="tun12" ;;
		VPNC3) IFACEname="tun13" ;;
		VPNC4) IFACEname="tun14" ;;
		VPNC5) IFACEname="tun15" ;;
		WGVPN1) IFACEname="wgc1" ;;
		WGVPN2) IFACEname="wgc2" ;;
		WGVPN3) IFACEname="wgc3" ;;
		WGVPN4) IFACEname="wgc4" ;;
		WGVPN5) IFACEname="wgc5" ;;
	esac
	echo "$IFACEname"
}

##------------------------------------=---##
## Modified by Martinski W. [2025-Mar-08] ##
##----------------------------------------##
Set_Interface_State()
{
    local interfaceLine  interface_UP  index
    interfaceLine="$(sed "$1!d" "$SCRIPT_INTERFACES_USER" | awk '{$1=$1};1')"

    if echo "$interfaceLine" | grep -qE "^(VPNC|WGVPN)"
    then
        IFACE_NAME="$(echo "$interfaceLine" | cut -f1 -d"#" | sed 's/ *$//')"
        IFACE_LOWER="$(Get_Interface_From_Name "$IFACE_NAME" | tr 'A-Z' 'a-z')"

        # Check if interface is 'up' vs 'down' #
        interface_UP=false
        if echo "$IFACE_NAME" | grep -q "^WGVPN"
        then
            if _Check_WG_ClientInterfaceUP_ "$IFACE_LOWER"
            then interface_UP=true ; fi
        else
            if _CheckNetClientInterfaceUP_ "$IFACE_LOWER"
            then interface_UP=true ; fi
        fi

        # Decide how to update the '#excluded' marker based on up/down #
        if echo "$interfaceLine" | grep -q "#excluded"
        then
            # The user has explicitly excluded this interface at some point #
            if "$interface_UP"
            then
                # If it was '#excluded - interface not up#' strip off the suffix #
                sed -i "$1 s/#excluded - interface not up#/#excluded#/" "$SCRIPT_INTERFACES_USER"
            else
                # The interface is 'down' so ensure we have "#excluded - interface not up#" #
                if echo "$interfaceLine" | grep -q "#excluded#$"
                then
                    sed -i "$1 s/#excluded$/#excluded - interface not up#/" "$SCRIPT_INTERFACES_USER"
                fi
            fi
        else
            # No '#excluded' marker => user wanted it included #
            if ! "$interface_UP"
            then
                # If it’s 'down' automatically exclude it with '- interface not up#' #
                sed -i "$1 s/$/ #excluded - interface not up#/" "$SCRIPT_INTERFACES_USER"
            fi
        fi
    fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-08] ##
##----------------------------------------##
Generate_Interface_List()
{
    local ifaceCount  ifaceEntryNum  interfaceLine  interface_UP
	printf "\nRetrieving list of interfaces...\n\n"

    _GenerateIFaceList_()
    {
        ifaceCount="$(wc -l < "$SCRIPT_INTERFACES_USER")"
        COUNTER=1
        until [ "$COUNTER" -gt "$ifaceCount" ]
        do
	        Set_Interface_State "$COUNTER"
	        ifaceLine="$(sed "$COUNTER!d" "$SCRIPT_INTERFACES_USER" | awk '{$1=$1};1')"
	        printf "%2d)  %s\n" "$COUNTER" "$ifaceLine"
	        COUNTER="$((COUNTER + 1))"
        done
        printf " e)  Exit to Main Menu\n"
    }

	while true
	do
		ScriptHeader
		_GenerateIFaceList_
		printf "\n${BOLD}Select an interface to toggle inclusion in %s [1-%s]:${CLEARFORMAT}  " "$SCRIPT_NAME" "$ifaceCount"
		read -r ifaceEntryNum

		if [ "$ifaceEntryNum" = "e" ]
		then
			break
		elif ! Validate_Number "$ifaceEntryNum"
		then
			printf "\n${ERR}Please enter a valid number [1-${ifaceCount}].${CLEARFORMAT}\n"
			PressEnter
		elif [ "$ifaceEntryNum" -lt 1 ] || [ "$ifaceEntryNum" -gt "$ifaceCount" ]
		then
			printf "\n${ERR}Please enter a number between 1 and ${ifaceCount}.${CLEARFORMAT}\n"
			PressEnter
		else
			interfaceLine="$(sed "$ifaceEntryNum!d" "$SCRIPT_INTERFACES_USER" | awk '{$1=$1};1')"
			IFACE_NAME="$(echo "$interfaceLine" | cut -f1 -d"#" | sed 's/ *$//')"
			IFACE_LOWER="$(Get_Interface_From_Name "$IFACE_NAME" | tr 'A-Z' 'a-z')"

			interface_UP=false
			if echo "$IFACE_NAME" | grep -q "^WGVPN"
			then
			    if _Check_WG_ClientInterfaceUP_ "$IFACE_LOWER"
			    then interface_UP=true ; fi
			else
			    if _CheckNetClientInterfaceUP_ "$IFACE_LOWER"
			    then interface_UP=true ; fi
			fi

			if echo "$interfaceLine" | grep -q "#excluded"
            then
				if "$interface_UP"
				then
					sed -i "$ifaceEntryNum"'s/ #excluded - interface not up#//' "$SCRIPT_INTERFACES_USER"
					sed -i "$ifaceEntryNum"'s/ #excluded#//' "$SCRIPT_INTERFACES_USER"
				else
					sed -i "$ifaceEntryNum"'s/ #excluded#/ #excluded - interface not up#/' "$SCRIPT_INTERFACES_USER"
				fi
			else
				if "$interface_UP"
				then
					sed -i "$ifaceEntryNum"'s/$/ #excluded#/' "$SCRIPT_INTERFACES_USER"
				else
					sed -i "$ifaceEntryNum"'s/$/ #excluded - interface not up#/' "$SCRIPT_INTERFACES_USER"
				fi
			fi
			sed -i 's/ *$//' "$SCRIPT_INTERFACES_USER"
			printf "\n"
		fi
	done
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
Download_File()
{ /usr/sbin/curl -LSs --retry 4 --retry-delay 5 --retry-connrefused "$1" -o "$2" ; }

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_Check_WebGUI_Page_Exists_()
{
   local webPageStr  webPageFile  theWebPage

   if [ ! -f "$TEMP_MENU_TREE" ]
   then echo "NONE" ; return 1 ; fi

   theWebPage="NONE"
   webPageStr="$(grep -E -m1 "^$webPageLineRegExp" "$TEMP_MENU_TREE")"
   if [ -n "$webPageStr" ]
   then
       webPageFile="$(echo "$webPageStr" | grep -owE "$webPageFileRegExp" | head -n1)"
       if [ -n "$webPageFile" ] && [ -s "${SCRIPT_WEBPAGE_DIR}/$webPageFile" ]
       then theWebPage="$webPageFile" ; fi
   fi
   echo "$theWebPage"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Get_WebUI_Page()
{
	local webPageFile  webPagePath

	MyWebPage="$(_Check_WebGUI_Page_Exists_)"

	for indx in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
	do
		webPageFile="user${indx}.asp"
		webPagePath="${SCRIPT_WEBPAGE_DIR}/$webPageFile"

		if [ -s "$webPagePath" ] && \
		   [ "$(md5sum < "$1")" = "$(md5sum < "$webPagePath")" ]
		then
			MyWebPage="$webPageFile"
			break
		elif [ "$MyWebPage" = "NONE" ] && [ ! -s "$webPagePath" ]
		then
			MyWebPage="$webPageFile"
		fi
	done
}

### function based on @dave14305's FlexQoS webconfigpage function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Get_WebUI_URL()
{
	local urlPage  urlProto  urlDomain  urlPort  lanPort

	if [ ! -f "$TEMP_MENU_TREE" ]
	then
		echo "**ERROR**: WebUI page NOT mounted"
		return 1
	fi

	urlPage="$(sed -nE "/$SCRIPT_NAME/ s/.*url\: \"(user[0-9]+\.asp)\".*/\1/p" "$TEMP_MENU_TREE")"

	if [ "$(nvram get http_enable)" -eq 1 ]; then
		urlProto="https"
	else
		urlProto="http"
	fi
	if [ -n "$(nvram get lan_domain)" ]; then
		urlDomain="$(nvram get lan_hostname).$(nvram get lan_domain)"
	else
		urlDomain="$(nvram get lan_ipaddr)"
	fi

	lanPort="$(nvram get ${urlProto}_lanport)"
	if [ "$lanPort" -eq 80 ] || [ "$lanPort" -eq 443 ]
	then
		urlPort=""
	else
		urlPort=":$lanPort"
	fi

	if echo "$urlPage" | grep -qE "^${webPageFileRegExp}$" && \
	   [ -s "${SCRIPT_WEBPAGE_DIR}/$urlPage" ]
	then
		echo "${urlProto}://${urlDomain}${urlPort}/${urlPage}" | tr "A-Z" "a-z"
	else
		echo "**ERROR**: WebUI page NOT found"
	fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_CreateMenuAddOnsSection_()
{
   if grep -qE "^${webPageMenuAddons}$" "$TEMP_MENU_TREE" && \
      grep -qE "${webPageHelpSupprt}$" "$TEMP_MENU_TREE"
   then return 0 ; fi

   lineinsBefore="$(($(grep -n "^exclude:" "$TEMP_MENU_TREE" | cut -f1 -d':') - 1))"

   sed -i "$lineinsBefore""i\
${BEGIN_MenuAddOnsTag}\n\
,\n{\n\
${webPageMenuAddons}\n\
index: \"menu_Addons\",\n\
tab: [\n\
{url: \"javascript:var helpwindow=window.open('\/ext\/shared-jy\/redirect.htm')\", ${webPageHelpSupprt}\n\
{url: \"NULL\", tabName: \"__INHERIT__\"}\n\
]\n}\n\
${ENDIN_MenuAddOnsTag}" "$TEMP_MENU_TREE"
}

### locking mechanism code credit to Martineau (@MartineauUK) ###
##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Mount_WebUI()
{
	Print_Output true "Mounting WebUI tab for $SCRIPT_NAME" "$PASS"
	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"
	Get_WebUI_Page "$SCRIPT_DIR/spdstats_www.asp"
	if [ "$MyWebPage" = "NONE" ]
	then
		Print_Output true "**ERROR** Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
		flock -u "$FD"
		return 1
	fi
	cp -fp "$SCRIPT_DIR/spdstats_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyWebPage"
	echo "$SCRIPT_NAME" > "$SCRIPT_WEBPAGE_DIR/$(echo "$MyWebPage" | cut -f1 -d'.').title"

	if [ "$(/bin/uname -o)" = "ASUSWRT-Merlin" ]
	then
		if [ ! -f /tmp/index_style.css ]; then
			cp -fp /www/index_style.css /tmp/
		fi

		if ! grep -q '.menu_Addons' /tmp/index_style.css
		then
			echo ".menu_Addons { background: url(ext/shared-jy/addons.png); }" >> /tmp/index_style.css
		fi

		umount /www/index_style.css 2>/dev/null
		mount -o bind /tmp/index_style.css /www/index_style.css

		if [ ! -f "$TEMP_MENU_TREE" ]; then
			cp -fp /www/require/modules/menuTree.js "$TEMP_MENU_TREE"
		fi
		sed -i "\\~$MyWebPage~d" "$TEMP_MENU_TREE"

		_CreateMenuAddOnsSection_

		sed -i "/url: \"javascript:var helpwindow=window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyWebPage\", tabName: \"$SCRIPT_NAME\"}," "$TEMP_MENU_TREE"

		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind "$TEMP_MENU_TREE" /www/require/modules/menuTree.js
	fi
	flock -u "$FD"
	Print_Output true "Mounted $SCRIPT_NAME WebUI page as $MyWebPage" "$PASS"
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_CheckFor_WebGUI_Page_()
{
   if [ "$(_Check_WebGUI_Page_Exists_)" = "NONE" ]
   then Mount_WebUI ; fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
AutomaticMode()
{
	case "$1" in
		enable)
			if AutomaticMode check
			then
			    printf "\nAutomatic speedtests are already ${GRNct}ENABLED${CLRct}.\n\n"
			    return 0
			fi
			sed -i 's/^AUTOMATICMODE=.*$/AUTOMATICMODE=true/' "$SCRIPT_CONF"
			Auto_Cron create 2>/dev/null
			printf "Automatic speedtests are now ${GRNct}ENABLED${CLRct}.\n\n"
		;;
		disable)
			if ! AutomaticMode check
			then
			    printf "\nAutomatic speedtests are already ${REDct}DISABLED${CLRct}.\n\n"
			    return 0
			fi
			sed -i 's/^AUTOMATICMODE=.*$/AUTOMATICMODE=false/' "$SCRIPT_CONF"
			Auto_Cron delete 2>/dev/null
			printf "Automatic speedtests are now ${REDct}DISABLED${CLRct}.\n\n"
		;;
		check)
			AUTOMATICMODE="$(_GetConfigParam_ AUTOMATICMODE 'true')"
			if [ "$AUTOMATICMODE" = "true" ]
			then return 0; else return 1; fi
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
CronTestSchedule()
{
	case "$1" in
		update)
			sed -i 's/^SCHDAYS=.*$/SCHDAYS='"$(echo "$2" | sed 's/0/Sun/;s/1/Mon/;s/2/Tues/;s/3/Wed/;s/4/Thurs/;s/5/Fri/;s/6/Sat/;')"'/' "$SCRIPT_CONF"
			sed -i 's~^SCHHOURS=.*$~SCHHOURS='"$3"'~' "$SCRIPT_CONF"
			sed -i 's~^SCHMINS=.*$~SCHMINS='"$4"'~' "$SCRIPT_CONF"
			Auto_Cron delete 2>/dev/null
			AutomaticMode check && Auto_Cron create 2>/dev/null
		;;
		check)
			SCHDAYS="$(_GetConfigParam_ SCHDAYS '*')"
			SCHHOURS="$(_GetConfigParam_ SCHHOURS '*')"
			SCHMINS="$(_GetConfigParam_ SCHMINS '12,42')"
			echo "${SCHDAYS}|${SCHHOURS}|${SCHMINS}"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
ScriptStorageLocation()
{
	case "$1" in
		usb)
			printf "Please wait..."
			sed -i 's/^STORAGELOCATION=.*$/STORAGELOCATION=usb/' "$SCRIPT_CONF"
			mkdir -p "/opt/share/$SCRIPT_NAME_LOWER.d/"
			rm -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/spdstats.db-shm"
			rm -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/spdstats.db-wal"
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/csv" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/.interfaces" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/.interfaces_user" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/.interfaces_user.bak" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/.databaseupgraded" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/config" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/config.bak" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d/spdtitletext.js" "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d"/spdstats.db* "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/jffs/addons/$SCRIPT_NAME_LOWER.d"/lastx_*.csv "/opt/share/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			SCRIPT_CONF="/opt/share/${SCRIPT_NAME_LOWER}.d/config"
			SPEEDSTATS_DB="/opt/share/${SCRIPT_NAME_LOWER}.d/spdstats.db"
			CSV_OUTPUT_DIR="/opt/share/${SCRIPT_NAME_LOWER}.d/csv"
			ScriptStorageLocation load true
			sleep 2
		    ;;
		jffs)
			printf "Please wait..."
			sed -i 's/^STORAGELOCATION=.*$/STORAGELOCATION=jffs/' "$SCRIPT_CONF"
			mkdir -p "/jffs/addons/$SCRIPT_NAME_LOWER.d/"
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/csv" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/.interfaces" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/.interfaces_user" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/.interfaces_user.bak" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/.databaseupgraded" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/config" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/config.bak" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d/spdtitletext.js" "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d"/spdstats.db* "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			mv -f "/opt/share/$SCRIPT_NAME_LOWER.d"/lastx_*.csv "/jffs/addons/$SCRIPT_NAME_LOWER.d/" 2>/dev/null
			SCRIPT_CONF="/jffs/addons/${SCRIPT_NAME_LOWER}.d/config"
			SPEEDSTATS_DB="/jffs/addons/${SCRIPT_NAME_LOWER}.d/spdstats.db"
			CSV_OUTPUT_DIR="/jffs/addons/${SCRIPT_NAME_LOWER}.d/csv"
			ScriptStorageLocation load true
			sleep 2
		    ;;
		check)
			STORAGELOCATION="$(_GetConfigParam_ STORAGELOCATION jffs)"
			echo "$STORAGELOCATION"
		    ;;
		load)
			STORAGELOCATION="$(ScriptStorageLocation check)"
			if [ "$STORAGELOCATION" = "usb" ]
			then
				SCRIPT_STORAGE_DIR="/opt/share/${SCRIPT_NAME_LOWER}.d"
			elif [ "$STORAGELOCATION" = "jffs" ]
			then
				SCRIPT_STORAGE_DIR="/jffs/addons/${SCRIPT_NAME_LOWER}.d"
			fi
			chmod 777 "$SCRIPT_STORAGE_DIR"
			SPEEDSTATS_DB="$SCRIPT_STORAGE_DIR/spdstats.db"
			CSV_OUTPUT_DIR="$SCRIPT_STORAGE_DIR/csv"
			SCRIPT_INTERFACES="$SCRIPT_STORAGE_DIR/.interfaces"
			SCRIPT_INTERFACES_USER="$SCRIPT_STORAGE_DIR/.interfaces_user"
			if [ $# -gt 1 ] && [ "$2" = "true" ]
			then _UpdateJFFS_FreeSpaceInfo_ ; fi
		    ;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
OutputTimeMode()
{
	case "$1" in
		unix)
			sed -i 's/^OUTPUTTIMEMODE=.*$/OUTPUTTIMEMODE=unix/' "$SCRIPT_CONF"
			printf "Please wait..."
			Generate_CSVs
		;;
		non-unix)
			sed -i 's/^OUTPUTTIMEMODE=.*$/OUTPUTTIMEMODE=non-unix/' "$SCRIPT_CONF"
			printf "Please wait..."
			Generate_CSVs
		;;
		check)
			OUTPUTTIMEMODE="$(_GetConfigParam_ OUTPUTTIMEMODE unix)"
			echo "$OUTPUTTIMEMODE"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
SpeedtestBinary()
{
	case "$1" in
		builtin)
			sed -i 's/^SPEEDTESTBINARY=.*$/SPEEDTESTBINARY=builtin/' "$SCRIPT_CONF"
		;;
		external)
			sed -i 's/^SPEEDTESTBINARY=.*$/SPEEDTESTBINARY=external/' "$SCRIPT_CONF"
		;;
		check)
			SPEEDTESTBINARY="$(_GetConfigParam_ SPEEDTESTBINARY)"
			[ -z "$SPEEDTESTBINARY" ] && SPEEDTESTBINARY="$(_GetDefaultSpeedTestBinary_)"
			echo "$SPEEDTESTBINARY"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
DaysToKeep()
{
	local MINvalue=15  MAXvalue=365  #Days#
	case "$1" in
		update)
			daysToKeep="$(DaysToKeep check)"
			exitLoop=false
			while true
			do
				ScriptHeader
				printf "${BOLD}Current number of days to keep data: ${GRNct}${daysToKeep}${CLRct}\n\n"
				printf "${BOLD}Please enter the maximum number of days\nto keep the data for [${MINvalue}-${MAXvalue}] (e=Exit):${CLEARFORMAT}  "
				read -r daystokeep_choice
				if [ -z "$daystokeep_choice" ] && \
				   echo "$daysToKeep" | grep -qE "^([1-9][0-9]{1,2})$" && \
				   [ "$daysToKeep" -ge "$MINvalue" ] && [ "$daysToKeep" -le "$MAXvalue" ]
				then
					exitLoop=true
					break
				elif [ "$daystokeep_choice" = "e" ]
				then
					exitLoop=true
					break
				elif ! Validate_Number "$daystokeep_choice"
				then
					printf "\n${ERR}Please enter a valid number [${MINvalue}-${MAXvalue}].${CLEARFORMAT}\n"
					PressEnter
				elif [ "$daystokeep_choice" -lt "$MINvalue" ] || [ "$daystokeep_choice" -gt "$MAXvalue" ]
				then
					printf "\n${ERR}Please enter a number between ${MINvalue} and ${MAXvalue}.${CLEARFORMAT}\n"
					PressEnter
				else
					daysToKeep="$daystokeep_choice"
					break
				fi
			done

			if "$exitLoop"
			then
				echo ; return 1
			else
				DAYSTOKEEP="$daysToKeep"
				sed -i 's/^DAYSTOKEEP=.*$/DAYSTOKEEP='"$DAYSTOKEEP"'/' "$SCRIPT_CONF"
				echo ; return 0
			fi
		;;
		check)
			DAYSTOKEEP="$(_GetConfigParam_ DAYSTOKEEP 30)"
			echo "$DAYSTOKEEP"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
LastXResults()
{
	local MINvalue=5  MAXvalue=100  #Results#
	case "$1" in
		update)
			lastXResults="$(LastXResults check)"
			exitLoop=false
			while true
			do
				ScriptHeader
				printf "${BOLD}Current number of results to display: ${GRNct}${lastXResults}${CLRct}\n\n"
				printf "${BOLD}Please enter the maximum number of results\nto display in the WebUI [${MINvalue}-${MAXvalue}] (e=Exit):${CLEARFORMAT}  "
				read -r lastx_choice
				if [ -z "$lastx_choice" ] && \
				   echo "$lastXResults" | grep -qE "^([1-9][0-9]{0,2})$" && \
				   [ "$lastXResults" -ge "$MINvalue" ] && [ "$lastXResults" -le "$MAXvalue" ]
				then
					exitLoop=true
					break
				elif [ "$lastx_choice" = "e" ]
				then
					exitLoop=true
					break
				elif ! Validate_Number "$lastx_choice"
				then
					printf "\n${ERR}Please enter a valid number [${MINvalue}-${MAXvalue}].${CLEARFORMAT}\n"
					PressEnter
				elif [ "$lastx_choice" -lt "$MINvalue" ] || [ "$lastx_choice" -gt "$MAXvalue" ]
				then
					printf "\n${ERR}Please enter a number between ${MINvalue} and ${MAXvalue}.${CLEARFORMAT}\n"
					PressEnter
				else
					lastXResults="$lastx_choice"
					break
				fi
			done

			if "$exitLoop"
			then
				echo ; return 1
			else
				LASTXRESULTS="$lastXResults"
				sed -i 's/^LASTXRESULTS=.*$/LASTXRESULTS='"$LASTXRESULTS"'/' "$SCRIPT_CONF"

				IFACELIST=""
				while IFS='' read -r line || [ -n "$line" ]
				do
					IFACELIST="$IFACELIST $(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				done < "$SCRIPT_INTERFACES_USER"

				IFACELIST="$(echo "$IFACELIST" | cut -c2-)"
				if [ -n "$IFACELIST" ]
				then
					local glxIndx=0
					for IFACE_NAME in $IFACELIST
					do
						glxIndx="$((glxIndx + 1))"
						Generate_LastXResults "$IFACE_NAME" "$glxIndx"
					done
				fi
				echo ; return 0
			fi
		;;
		check)
			LASTXRESULTS="$(_GetConfigParam_ LASTXRESULTS 10)"
			echo "$LASTXRESULTS"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
StoreResultURL()
{
	case "$1" in
	enable)
		sed -i 's/^STORERESULTURL=.*$/STORERESULTURL=true/' "$SCRIPT_CONF"
	;;
	disable)
		sed -i 's/^STORERESULTURL=.*$/STORERESULTURL=false/' "$SCRIPT_CONF"
	;;
	check)
		STORERESULTURL="$(_GetConfigParam_ STORERESULTURL 'true')"
		echo "$STORERESULTURL"
	;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
ExcludeFromQoS()
{
	case "$1" in
	enable)
		sed -i 's/^EXCLUDEFROMQOS=.*$/EXCLUDEFROMQOS=true/' "$SCRIPT_CONF"
	;;
	disable)
		sed -i 's/^EXCLUDEFROMQOS=.*$/EXCLUDEFROMQOS=false/' "$SCRIPT_CONF"
	;;
	check)
		EXCLUDEFROMQOS="$(_GetConfigParam_ EXCLUDEFROMQOS 'true')"
		echo "$EXCLUDEFROMQOS"
	;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
AutoBWEnable()
{
	case "$1" in
	enable)
		sed -i 's/^AUTOBW_ENABLED=.*$/AUTOBW_ENABLED=true/' "$SCRIPT_CONF"
	;;
	disable)
		sed -i 's/^AUTOBW_ENABLED=.*$/AUTOBW_ENABLED=false/' "$SCRIPT_CONF"
	;;
	check)
		AUTOBW_ENABLED="$(_GetConfigParam_ AUTOBW_ENABLED 'false')"
		echo "$AUTOBW_ENABLED"
	;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
AutoBWConf()
{
	case "$1" in
		update)
			sed -i 's/^AUTOBW_'"$2"'_'"$3"'=.*$/AUTOBW_'"$2"'_'"$3"'='"$4"'/' "$SCRIPT_CONF"
		;;
		check)
			AUTOBW_PARAM="$(_GetConfigParam_ "AUTOBW_${2}_${3}")"
			echo "$AUTOBW_PARAM"
		;;
	esac
}

#----------------------------------------------------------------------------
# $1 fieldname $2 tablename $3 frequency (hours) $4 length (days)
# $5 outputfile $6 outputfrequency $7 interfacename $8 sqlfile $9 timestamp
#----------------------------------------------------------------------------
##----------------------------------------##
## Modified by Martinski W. [2025-Jan-19] ##
##----------------------------------------##
WriteSql_ToFile()
{
	timenow="$9"
	maxcount="$(echo "$3" "$4" | awk '{printf ((24*$2)/$1)}')"

	if ! echo "$5" | grep -q "day"
	then
		{
		   echo ".mode csv"
		   echo ".headers off"
		   echo ".output ${5}_${6}_${7}.tmp"
		   echo "PRAGMA temp_store=1;"
		   echo "SELECT '$1' Metric,Min(strftime('%s',datetime(strftime('%Y-%m-%d %H:00:00',datetime([Timestamp],'unixepoch'))))) Time,IFNULL(printf('%f',Avg($1)),'NaN') Value FROM $2 WHERE ([Timestamp] >= strftime('%s',datetime($timenow,'unixepoch','-$maxcount hour'))) GROUP BY strftime('%m',datetime([Timestamp],'unixepoch')),strftime('%d',datetime([Timestamp],'unixepoch')),strftime('%H',datetime([Timestamp],'unixepoch')) ORDER BY [Timestamp] DESC;"
		} > "$8"
	else
		{
		   echo ".mode csv"
		   echo ".headers off"
		   echo ".output ${5}_${6}_${7}.tmp"
		   echo "PRAGMA temp_store=1;"
		   echo "SELECT '$1' Metric,Max(strftime('%s',datetime([Timestamp],'unixepoch','localtime','start of day','utc'))) Time,IFNULL(printf('%f',Avg($1)),'NaN') Value FROM $2 WHERE ([Timestamp] > strftime('%s',datetime($timenow,'unixepoch','localtime','start of day','utc','+1 day','-$maxcount day'))) GROUP BY strftime('%m',datetime([Timestamp],'unixepoch','localtime')),strftime('%d',datetime([Timestamp],'unixepoch','localtime')) ORDER BY [Timestamp] DESC;"
		} > "$8"
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2024-Nov-15] ##
##----------------------------------------##
WriteStats_ToJS()
{
	if [ $# -lt 4 ] ; then return 1 ; fi

	if [ -f "$2" ]
	then
	    sed -i -e '/^}/d;/^function/d;/^document.getElementById/d;/^databaseResetDone/d;' "$2"
	    awk 'NF' "$2" > "${2}.tmp"
	    mv -f "${2}.tmp" "$2"
	fi
	printf "\nfunction %s(){\n" "$3" >> "$2"
	html='document.getElementById("'"$4"'").innerHTML="'

	while IFS='' read -r line || [ -n "$line" ]
	do html="${html}${line}"
	done < "$1"
	html="$html"'"'

	if [ $# -lt 5 ] || [ -z "$5" ]
	then printf "%s\n}\n" "$html" >> "$2"
	else printf "%s;\n%s\n}\n" "$html" "$5" >> "$2"
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-03] ##
##----------------------------------------##
GenerateServerList()
{
	if [ ! -f /opt/bin/jq ] && [ -x /opt/bin/opkg ]
	then
		opkg update
		opkg install jq
	fi
	if [ $# -lt 2 ] || [ -z "$2" ]
	then promptforservername=""
	else promptforservername="$2"
	fi
	printf "Generating list of closest servers for %s...\n\n" "$1"
	CONFIG_STRING=""
	LICENSE_STRING="--accept-license --accept-gdpr"
	SPEEDTEST_BINARY=""
	if [ "$(SpeedtestBinary check)" = "builtin" ]
	then
		SPEEDTEST_BINARY=/usr/sbin/ookla
	elif [ "$(SpeedtestBinary check)" = "external" ]
	then
		SPEEDTEST_BINARY="$OOKLA_DIR/speedtest"
	fi
	if [ "$SPEEDTEST_BINARY" = /usr/sbin/ookla ]; then
		CONFIG_STRING="-c http://www.speedtest.net/api/embed/vz0azjarf5enop8a/config"
		LICENSE_STRING=""
	fi
	serverList="$("$SPEEDTEST_BINARY" $CONFIG_STRING --interface="$(Get_Interface_From_Name "$1")" --servers --format="json" $LICENSE_STRING)" 2>/dev/null
	if [ -z "$serverList" ]
	then
		Print_Output true "Error retrieving server list for for $1" "$CRIT"
		serverno="exit"
		return 1
	fi
	serverCount="$(echo "$serverList" | jq '.servers | length')"
	COUNTER=1
	until [ "$COUNTER" -gt "$serverCount" ]
	do
		serverdetails="$(echo "$serverList" | jq -r --argjson index "$((COUNTER-1))" '.servers[$index] | .id')|$(echo "$serverList" | jq -r --argjson index "$((COUNTER-1))" '.servers[$index] | .name + " (" + .location + ", " + .country + ")"')"

		printf "%2d)  %s\n" "$COUNTER" "$serverdetails"
		COUNTER="$((COUNTER + 1))"
	done

	printf "\n e)  Go back\n"

	while true
	do
		printf "\n${BOLD}Please select a server from the list above [1-%s].${CLEARFORMAT}" "$serverCount"
		printf "\n${BOLD}Or press ${GRNct}c${CLRct} to enter a known server ID.${CLEARFORMAT}"
		printf "\n${BOLD}Enter answer:${CLEARFORMAT}  "
		read -r server

		if [ "$server" = "e" ]
		then
			serverno="exit"
			break
		elif [ "$server" = "c" ]
		then
				while true
				do
					printf "\n${BOLD}Please enter server ID (WARNING: ID is NOT validated) or ${GRNct}e${CLRct} to go back.${CLEARFORMAT}  "
					read -r customserver
					if [ "$customserver" = "e" ]
					then
						break
					elif ! Validate_Number "$customserver"
					then
						printf "\n${ERR}Please enter a valid number.${CLEARFORMAT}\n"
					else
						serverno="$customserver"
						if [ "$promptforservername" != "no" ]
						then
							while true
							do
								printf "\n${BOLD}Would you like to enter a name for this server? (default: Custom) (y/n)?${CLEARFORMAT}  "
								read -r servername_select
								
								if [ "$servername_select" = "n" ] || [ "$servername_select" = "N" ]
								then
									servername="Custom"
									break
								elif [ "$servername_select" = "y" ] || [ "$servername_select" = "Y" ]
								then
									printf "\n${BOLD}Please enter the name for this server:${CLEARFORMAT}  "
									read -r servername
									printf "\n${BOLD}%s${CLEARFORMAT}\n" "$servername"
									printf "\n${BOLD}Is that correct (y/n)?${CLEARFORMAT}  "
									read -r servername_confirm
									if [ "$servername_confirm" = "y" ] || \
									   [ "$servername_confirm" = "Y" ]
									then
										break
									else
										printf "\n${ERR}Please enter y or n${CLEARFORMAT}\n"
									fi
								else
									printf "\n${ERR}Please enter y or n${CLEARFORMAT}\n"
								fi
							done
						else
							servername="Custom"
						fi
						printf "\n"
						return 0
					fi
				done
		elif ! Validate_Number "$server"
		then
			printf "\n${ERR}Please enter a valid number [1-%s]${CLEARFORMAT}\n" "$serverCount"
		else
			if [ "$server" -lt 1 ] || [ "$server" -gt "$serverCount" ]; then
				printf "\n${ERR}Please enter a number between 1 and %s.${CLEARFORMAT}\n" "$serverCount"
			else
				serverno="$(echo "$serverList" | jq -r --argjson index "$((server-1))" '.servers[$index] | .id')"
				servername="$(echo "$serverList" | jq -r --argjson index "$((server-1))" '.servers[$index] | .name + " (" + .location + ", " + .country + ")"')"
				printf "\n"
				break
			fi
		fi
	done
}

GenerateServerList_WebUI()
{
	serverlistfile="$2"
	rm -f "/tmp/$serverlistfile.txt"
	rm -f "$SCRIPT_WEB_DIR/$serverlistfile.htm"
	SPEEDTEST_BINARY=""
	if [ "$(SpeedtestBinary check)" = "builtin" ]
	then
		SPEEDTEST_BINARY=/usr/sbin/ookla
	elif [ "$(SpeedtestBinary check)" = "external" ]
	then
		SPEEDTEST_BINARY="$OOKLA_DIR/speedtest"
	fi
	CONFIG_STRING=""
	LICENSE_STRING="--accept-license --accept-gdpr"
	if [ "$SPEEDTEST_BINARY" = /usr/sbin/ookla ]
	then
		CONFIG_STRING="-c http://www.speedtest.net/api/embed/vz0azjarf5enop8a/config"
		LICENSE_STRING=""
	fi

	spdifacename="$1"

	if [ ! -f /opt/bin/jq ] && [ -x /opt/bin/opkg ]
	then
		opkg update
		opkg install jq
	fi

	if [ "$spdifacename" = "ALL" ]
	then
		IFACELIST=""
		while IFS='' read -r line || [ -n "$line" ]
		do
			if [ "$(echo "$line" | grep -c "interface not up")" -eq 0 ]
			then
				IFACELIST="$IFACELIST $(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
			fi
		done < "$SCRIPT_INTERFACES_USER"
		IFACELIST="$(echo "$IFACELIST" | cut -c2-)"

		for IFACE_NAME in $IFACELIST
		do
			serverList="$("$SPEEDTEST_BINARY" $CONFIG_STRING --interface="$(Get_Interface_From_Name "$IFACE_NAME")" --servers --format="json" $LICENSE_STRING)" 2>/dev/null
			serverCount="$(echo "$serverList" | jq '.servers | length')"
			COUNTER=1
			until [ $COUNTER -gt "$serverCount" ]
			do
				printf "%s|%s\\n" "$(echo "$serverList" | jq -r --argjson index "$((COUNTER-1))" '.servers[$index] | .id')" "$(echo "$serverList" | jq -r --argjson index "$((COUNTER-1))" '.servers[$index] | .name + " (" + .location + ", " + .country + ")"')"  >> "/tmp/$serverlistfile.tmp"
				COUNTER=$((COUNTER + 1))
			done
			printf "-----\\n" >> "/tmp/$serverlistfile.tmp"
		done
	else
		serverList="$("$SPEEDTEST_BINARY" $CONFIG_STRING --interface="$(Get_Interface_From_Name "$spdifacename")" --servers --format="json" $LICENSE_STRING)" 2>/dev/null
		serverCount="$(echo "$serverList" | jq '.servers | length')"
		COUNTER=1
		until [ $COUNTER -gt "$serverCount" ]
		do
			printf "%s|%s\\n" "$(echo "$serverList" | jq -r --argjson index "$((COUNTER-1))" '.servers[$index] | .id')" "$(echo "$serverList" | jq -r --argjson index "$((COUNTER-1))" '.servers[$index] | .name + " (" + .location + ", " + .country + ")"')"  >> "/tmp/$serverlistfile.tmp"
			COUNTER=$((COUNTER + 1))
		done
	fi
	sleep 1
	mv "/tmp/$serverlistfile.tmp" "/tmp/$serverlistfile.txt"
	ln -s "/tmp/$serverlistfile.txt" "$SCRIPT_WEB_DIR/$serverlistfile.htm" 2>/dev/null
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
PreferredServer()
{
	case "$1" in
		update)
			GenerateServerList "$2"
			if [ "$serverno" != "exit" ]
			then
				sed -i 's/^PREFERREDSERVER_'"$2"'=.*$/PREFERREDSERVER_'"$2"'='"$serverno|$servername"'/' "$SCRIPT_CONF"
			else
				return 1
			fi
		;;
		enable)
			sed -i 's/^USEPREFERRED_'"$2"'=.*$/USEPREFERRED_'"$2"'=true/' "$SCRIPT_CONF"
		;;
		disable)
			sed -i 's/^USEPREFERRED_'"$2"'=.*$/USEPREFERRED_'"$2"'=false/' "$SCRIPT_CONF"
		;;
		check)
			USEPREFERRED="$(_GetConfigParam_ "USEPREFERRED_${2}" 'false')"
			if [ "$USEPREFERRED" = "true" ]
			then return 0; else return 1; fi
		;;
		list)
			PREFERREDSERVER="$(grep "^PREFERREDSERVER_${2}=" "$SCRIPT_CONF" | cut -f2 -d'=')"
			echo "$PREFERREDSERVER"
		;;
	esac
}

##-------------------------------------##
## Added by Martinski W. [2024-Nov-15] ##
##-------------------------------------##
_GetFileSize_()
{
   local sizeUnits  sizeInfo  fileSize
   if [ $# -eq 0 ] || [ -z "$1" ] || [ ! -s "$1" ]
   then echo 0; return 1 ; fi

   if [ $# -lt 2 ] || [ -z "$2" ] || \
      ! echo "$2" | grep -qE "^(B|KB|MB|GB|HR|HRx)$"
   then sizeUnits="B" ; else sizeUnits="$2" ; fi

   _GetNum_() { printf "%.1f" "$(echo "$1" | awk "{print $1}")" ; }

   case "$sizeUnits" in
       B|KB|MB|GB)
           fileSize="$(ls -1l "$1" | awk -F ' ' '{print $3}')"
           case "$sizeUnits" in
               KB) fileSize="$(_GetNum_ "($fileSize / $oneKByte)")" ;;
               MB) fileSize="$(_GetNum_ "($fileSize / $oneMByte)")" ;;
               GB) fileSize="$(_GetNum_ "($fileSize / $oneGByte)")" ;;
           esac
           echo "$fileSize"
           ;;
       HR|HRx)
           fileSize="$(ls -1lh "$1" | awk -F ' ' '{print $3}')"
           sizeInfo="${fileSize}B"
           if [ "$sizeUnits" = "HR" ]
           then echo "$sizeInfo" ; return 0 ; fi
           sizeUnits="$(echo "$sizeInfo" | tr -d '.0-9')"
           case "$sizeUnits" in
               MB) fileSize="$(_GetFileSize_ "$1" KB)"
                   sizeInfo="$sizeInfo [${fileSize}KB]"
                   ;;
               GB) fileSize="$(_GetFileSize_ "$1" MB)"
                   sizeInfo="$sizeInfo [${fileSize}MB]"
                   ;;
           esac
           echo "$sizeInfo"
           ;;
       *) echo 0 ;;
   esac
   return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Jan-19] ##
##-------------------------------------##
_Get_JFFS_Space_()
{
   local typex  total  usedx  freex  totalx
   local sizeUnits  sizeType  sizeInfo  sizeNum
   local jffsMountStr  jffsUsageStr  percentNum  percentStr

   if [ $# -lt 1 ] || [ -z "$1" ] || \
      ! echo "$1" | grep -qE "^(ALL|USED|FREE)$"
   then sizeType="ALL" ; else sizeType="$1" ; fi

   if [ $# -lt 2 ] || [ -z "$2" ] || \
      ! echo "$2" | grep -qE "^(KB|KBP|MBP|GBP|HR|HRx)$"
   then sizeUnits="KB" ; else sizeUnits="$2" ; fi

   _GetNum_() { printf "%.2f" "$(echo "$1" | awk "{print $1}")" ; }

   jffsMountStr="$(mount | grep '/jffs')"
   jffsUsageStr="$(df -kT /jffs | grep -E '.*[[:blank:]]+/jffs$')"

   if [ -z "$jffsMountStr" ] || [ -z "$jffsUsageStr" ]
   then echo "**ERROR**: JFFS is *NOT* mounted." ; return 1
   fi
   if echo "$jffsMountStr" | grep -qE "[[:blank:]]+[(]?ro[[:blank:],]"
   then echo "**ERROR**: JFFS is mounted READ-ONLY." ; return 2
   fi

   typex="$(echo "$jffsUsageStr" | awk -F ' ' '{print $2}')"
   total="$(echo "$jffsUsageStr" | awk -F ' ' '{print $3}')"
   usedx="$(echo "$jffsUsageStr" | awk -F ' ' '{print $4}')"
   freex="$(echo "$jffsUsageStr" | awk -F ' ' '{print $5}')"
   totalx="$total"
   if [ "$typex" = "ubifs" ] && [ "$((usedx + freex))" -ne "$total" ]
   then totalx="$((usedx + freex))" ; fi

   if [ "$sizeType" = "ALL" ] ; then echo "$totalx" ; return 0 ; fi

   case "$sizeUnits" in
       KB|KBP|MBP|GBP)
           case "$sizeType" in
               USED) sizeNum="$usedx"
                     percentNum="$(printf "%.1f" "$(_GetNum_ "($usedx * 100 / $totalx)")")"
                     percentStr="[${percentNum}%]"
                     ;;
               FREE) sizeNum="$freex"
                     percentNum="$(printf "%.1f" "$(_GetNum_ "($freex * 100 / $totalx)")")"
                     percentStr="[${percentNum}%]"
                     ;;
           esac
           case "$sizeUnits" in
                KB) sizeInfo="$sizeNum"
                    ;;
               KBP) sizeInfo="${sizeNum}.0KB $percentStr"
                    ;;
               MBP) sizeNum="$(_GetNum_ "($sizeNum / $oneKByte)")"
                    sizeInfo="${sizeNum}MB $percentStr"
                    ;;
               GBP) sizeNum="$(_GetNum_ "($sizeNum / $oneMByte)")"
                    sizeInfo="${sizeNum}GB $percentStr"
                    ;;
           esac
           echo "$sizeInfo"
           ;;
       HR|HRx)
           jffsUsageStr="$(df -hT /jffs | grep -E '.*[[:blank:]]+/jffs$')"
           case "$sizeType" in
               USED) usedx="$(echo "$jffsUsageStr" | awk -F ' ' '{print $4}')"
                     sizeInfo="${usedx}B"
                     ;;
               FREE) freex="$(echo "$jffsUsageStr" | awk -F ' ' '{print $5}')"
                     sizeInfo="${freex}B"
                     ;;
           esac
           if [ "$sizeUnits" = "HR" ]
           then echo "$sizeInfo" ; return 0 ; fi
           sizeUnits="$(echo "$sizeInfo" | tr -d '.0-9')"
           case "$sizeUnits" in
               KB) sizeInfo="$(_Get_JFFS_Space_ "$sizeType" KBP)" ;;
               MB) sizeInfo="$(_Get_JFFS_Space_ "$sizeType" MBP)" ;;
               GB) sizeInfo="$(_Get_JFFS_Space_ "$sizeType" GBP)" ;;
           esac
           echo "$sizeInfo"
           ;;
       *) echo 0 ;;
   esac
   return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
##--------------------------------------------------------##
## Minimum Reserved JFFS Available Free Space is roughly
## about 20% of total space or about 9MB to 10MB.
##--------------------------------------------------------##
_JFFS_MinReservedFreeSpace_()
{
   local jffsAllxSpace  jffsMinxSpace

   if ! jffsAllxSpace="$(_Get_JFFS_Space_ ALL KB)"
   then echo "$jffsAllxSpace" ; return 1 ; fi
   jffsAllxSpace="$(echo "$jffsAllxSpace" | awk '{printf("%s", $1 * 1024);}')"

   jffsMinxSpace="$(echo "$jffsAllxSpace" | awk '{printf("%d", $1 * 20 / 100);}')"
   if [ "$(echo "$jffsMinxSpace $ni9MByte" | awk -F ' ' '{print ($1 < $2)}')" -eq 1 ]
   then jffsMinxSpace="$ni9MByte"
   elif [ "$(echo "$jffsMinxSpace $tenMByte" | awk -F ' ' '{print ($1 > $2)}')" -eq 1 ]
   then jffsMinxSpace="$tenMByte"
   fi
   echo "$jffsMinxSpace" ; return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
##--------------------------------------------------------##
## Check JFFS free space *BEFORE* moving files from USB.
##--------------------------------------------------------##
_Check_JFFS_SpaceAvailable_()
{
   local requiredSpace  jffsFreeSpace  jffsMinxSpace
   if [ $# -eq 0 ] || [ -z "$1" ] || [ ! -d "$1" ] ; then return 0 ; fi

   [ "$1" = "/jffs/addons/${SCRIPT_NAME_LOWER}.d" ] && return 0

   if ! jffsFreeSpace="$(_Get_JFFS_Space_ FREE KB)" ; then return 1 ; fi
   if ! jffsMinxSpace="$(_JFFS_MinReservedFreeSpace_)" ; then return 1 ; fi
   jffsFreeSpace="$(echo "$jffsFreeSpace" | awk '{printf("%s", $1 * 1024);}')"

   requiredSpace="$(du -kc "$1" | grep -w 'total$' | awk -F ' ' '{print $1}')"
   requiredSpace="$(echo "$requiredSpace" | awk '{printf("%s", $1 * 1024);}')"
   requiredSpace="$(echo "$requiredSpace $jffsMinxSpace" | awk -F ' ' '{printf("%s", $1 + $2);}')"
   if [ "$(echo "$requiredSpace $jffsFreeSpace" | awk -F ' ' '{print ($1 < $2)}')" -eq 1 ]
   then return 0 ; fi

   ## Current JFFS Available Free Space is NOT sufficient ##
   requiredSpace="$(du -hc "$1" | grep -w 'total$' | awk -F ' ' '{print $1}')"
   errorMsg1="Not enough free space [$(_Get_JFFS_Space_ FREE HR)] available in JFFS."
   errorMsg2="Minimum storage space required: $requiredSpace"
   Print_Output true "${errorMsg1} ${errorMsg2}" "$CRIT"
   return 1
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_WriteVarDefToJSFile_()
{
   if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]
   then return 1; fi

   local varValue
   if [ $# -eq 3 ] && [ "$3" = "true" ]
   then varValue="$2"
   else varValue="'${2}'"
   fi

   local targetJSfile="$SCRIPT_STORAGE_DIR/spdtitletext.js"
   if [ ! -s "$targetJSfile" ]
   then
       echo "var $1 = ${varValue};" > "$targetJSfile"
   elif
      ! grep -q "^var $1 =.*" "$targetJSfile"
   then
       sed -i "1 i var $1 = ${varValue};" "$targetJSfile"
   elif
      ! grep -q "^var $1 = ${varValue};" "$targetJSfile"
   then
       sed -i "s/^var $1 =.*/var $1 = ${varValue};/" "$targetJSfile"
   fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_DelVarDefFromJSFile_()
{
   if [ $# -eq 0 ] || [ -z "$1" ] ; then return 1; fi

   local targetJSfile="$SCRIPT_STORAGE_DIR/spdtitletext.js"
   if [ -s "$targetJSfile" ] && \
      grep -q "^var $1 =.*" "$targetJSfile"
   then
       sed -i "/^var $1 =.*/d" "$targetJSfile"
   fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
JFFS_WarningLogTime()
{
   case "$1" in
       update)
           sed -i 's/^JFFS_MSGLOGTIME=.*$/JFFS_MSGLOGTIME='"$2"'/' "$SCRIPT_CONF"
           ;;
       check)
           JFFS_MSGLOGTIME="$(_GetConfigParam_ JFFS_MSGLOGTIME 0)"
           if ! echo "$JFFS_MSGLOGTIME" | grep -qE "^[0-9]+$"
           then JFFS_MSGLOGTIME=0
           fi
           echo "$JFFS_MSGLOGTIME"
           ;;
   esac
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_JFFS_WarnLowFreeSpace_()
{
   if [ $# -eq 0 ] || [ -z "$1" ] ; then return 0 ; fi
   local jffsWarningLogFreq  jffsWarningLogTime  storageLocStr
   local logPriNum  logTagStr  logMsgStr  currTimeSecs  currTimeDiff

   storageLocStr="$(ScriptStorageLocation check | tr 'a-z' 'A-Z')"
   if [ "$storageLocStr" = "JFFS" ]
   then
       if [ "$JFFS_LowFreeSpaceStatus" = "WARNING2" ]
       then
           logPriNum=2
           logTagStr="**ALERT**"
           jffsWarningLogFreq="$_12Hours"
       else
           logPriNum=3
           logTagStr="**WARNING**"
           jffsWarningLogFreq="$_24Hours"
       fi
   else
       if [ "$JFFS_LowFreeSpaceStatus" = "WARNING2" ]
       then
           logPriNum=3
           logTagStr="**WARNING**"
           jffsWarningLogFreq="$_24Hours"
       else
           logPriNum=4
           logTagStr="**NOTICE**"
           jffsWarningLogFreq="$_36Hours"
       fi
   fi
   jffsWarningLogTime="$(JFFS_WarningLogTime check)"

   currTimeSecs="$(date +'%s')"
   currTimeDiff="$(echo "$currTimeSecs $jffsWarningLogTime" | awk -F ' ' '{printf("%s", $1 - $2);}')"
   if [ "$currTimeDiff" -ge "$jffsWarningLogFreq" ]
   then
       JFFS_WarningLogTime update "$currTimeSecs"
       logMsgStr="${logTagStr} JFFS Available Free Space ($1) is getting LOW."
       logger -t "$SCRIPT_NAME" -p $logPriNum "$logMsgStr"
   fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_UpdateJFFS_FreeSpaceInfo_()
{
   local jffsFreeSpaceHR  jffsFreeSpace  jffsMinxSpace
   [ ! -d "$SCRIPT_STORAGE_DIR" ] && return 1

   jffsFreeSpaceHR="$(_Get_JFFS_Space_ FREE HRx)"
   _DelVarDefFromJSFile_ "jffsAvailableSpace"
   _WriteVarDefToJSFile_ "jffsAvailableSpaceStr" "$jffsFreeSpaceHR"

   if ! jffsFreeSpace="$(_Get_JFFS_Space_ FREE KB)" ; then return 1 ; fi
   if ! jffsMinxSpace="$(_JFFS_MinReservedFreeSpace_)" ; then return 1 ; fi
   jffsFreeSpace="$(echo "$jffsFreeSpace" | awk '{printf("%s", $1 * 1024);}')"

   JFFS_LowFreeSpaceStatus="OK"
   ## Warning Level 1 if JFFS Available Free Space is LESS than Minimum Reserved ##
   if [ "$(echo "$jffsFreeSpace $jffsMinxSpace" | awk -F ' ' '{print ($1 < $2)}')" -eq 1 ]
   then
       JFFS_LowFreeSpaceStatus="WARNING1"
       ## Warning Level 2 if JFFS Available Free Space is LESS than 8.0MB ##
       if [ "$(echo "$jffsFreeSpace $ei8MByte" | awk -F ' ' '{print ($1 < $2)}')" -eq 1 ]
       then
           JFFS_LowFreeSpaceStatus="WARNING2"
       fi
       _JFFS_WarnLowFreeSpace_ "$jffsFreeSpaceHR"
   fi
   _WriteVarDefToJSFile_ "jffsAvailableSpaceLow" "$JFFS_LowFreeSpaceStatus"
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_UpdateDatabaseFileSizeInfo_()
{
   local databaseFileSize
   [ ! -d "$SCRIPT_STORAGE_DIR" ] && return 1

   _UpdateJFFS_FreeSpaceInfo_
   databaseFileSize="$(_GetFileSize_ "$SPEEDSTATS_DB" HRx)"
   _WriteVarDefToJSFile_ "sqlDatabaseFileSize" "$databaseFileSize"
}

##-------------------------------------##
## Added by Martinski W. [2025-Jun-04] ##
##-------------------------------------##
_SQLCheckDBLogFileSize_()
{
   if [ "$(_GetFileSize_ "$sqlDBLogFilePath")" -gt "$sqlDBLogFileSize" ]
   then
       cp -fp "$sqlDBLogFilePath" "${sqlDBLogFilePath}.BAK"
       echo -n > "$sqlDBLogFilePath"
   fi
}

_SQLGetDBLogTimeStamp_()
{ printf "[$(date +"$sqlDBLogDateTime")]" ; }

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-05] ##
##----------------------------------------##
_ApplyDatabaseSQLCmds_()
{
    local errorCount=0  maxErrorCount=3  callFlag
    local triesCount=0  maxTriesCount=10  sqlErrorMsg
    local tempLogFilePath="/tmp/${SCRIPT_NAME}Stats_TMP_$$.LOG"
    local debgLogFilePath="/tmp/${SCRIPT_NAME}Stats_DEBUG_$$.LOG"
    local debgLogSQLcmds=false

    if [ $# -gt 1 ] && [ -n "$2" ]
    then callFlag="$2"
    else callFlag="err"
    fi

    resultStr=""
    foundError=false ; foundLocked=false
    rm -f "$tempLogFilePath" "$debgLogFilePath"

    while [ "$errorCount" -lt "$maxErrorCount" ] && \
          [ "$((triesCount++))" -lt "$maxTriesCount" ]
    do
        if "$SQLITE3_PATH" "$SPEEDSTATS_DB" < "$1" >> "$tempLogFilePath" 2>&1
        then foundError=false ; foundLocked=false ; break
        fi
        sqlErrorMsg="$(cat "$tempLogFilePath")"

        if echo "$sqlErrorMsg" | grep -qE "^(Parse error|Runtime error|Error:|Illegal instruction)"
        then
            if echo "$sqlErrorMsg" | grep -qE "^(Parse|Runtime) error .*: database is locked"
            then
                foundLocked=true ; maxTriesCount=25
                echo -n > "$tempLogFilePath"  ##Clear for next error found##
                sleep 2 ; continue
            fi
            errorCount="$((errorCount + 1))"
            foundError=true ; foundLocked=false
            Print_Output true "SQLite3 failure[$callFlag]: $sqlErrorMsg" "$ERR"
        fi

        if ! "$debgLogSQLcmds"
        then
           debgLogSQLcmds=true
           {
              echo "==========================================="
              echo "$(_SQLGetDBLogTimeStamp_) BEGIN [$callFlag]"
              echo "Database: $SPEEDSTATS_DB"
           } > "$debgLogFilePath"
        fi
        cat "$tempLogFilePath" >> "$debgLogFilePath"
        echo -n > "$tempLogFilePath"  ##Clear for next error found##
        [ "$triesCount" -ge "$maxTriesCount" ] && break
        [ "$errorCount" -ge "$maxErrorCount" ] && break
        sleep 1
    done

    if "$debgLogSQLcmds"
    then
       {
          echo "--------------------------------"
          cat "$1"
          echo "--------------------------------"
          echo "$(_SQLGetDBLogTimeStamp_) END [$callFlag]"
       } >> "$debgLogFilePath"
       cat "$debgLogFilePath" >> "$sqlDBLogFilePath"
    fi

    rm -f "$tempLogFilePath" "$debgLogFilePath"
    if "$foundError"
    then resultStr="reported error(s)."
    elif "$foundLocked"
    then resultStr="found database locked."
    else resultStr="completed successfully."
    fi
    if "$foundError" || "$foundLocked"
    then
        Print_Output true "SQLite process ${resultStr}" "$ERR"
    fi
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_Optimize_Database_()
{
   renice 15 $$
   local foundError  foundLocked  resultStr  SQLTable  sqlProcSuccess

   Print_Output true "Running database analysis and optimization..." "$PASS"

   sqlProcSuccess=true
   local optIndx=0
   for dbtable in $FULL_IFACELIST
   do
       SQLTable="spdstats_$dbtable"
       {
          echo "PRAGMA temp_store=1;"
          echo "PRAGMA journal_mode=TRUNCATE;"
          echo "PRAGMA analysis_limit=0;"
          echo "PRAGMA cache_size=-20000;"
          echo "ANALYZE $SQLTable;"
          echo "VACUUM;"
       } > /tmp/spdMerlin-trim.sql
       optIndx="$((optIndx + 1))"
       _ApplyDatabaseSQLCmds_ /tmp/spdMerlin-trim.sql "opt$optIndx"

       rm -f /tmp/spdMerlin-trim.sql
       if "$foundError" || "$foundLocked"
       then
           sqlProcSuccess=false
           Print_Output true "Database [$SQLTable] analysis and optimization ${resultStr}" "$ERR"
       fi
   done

   "$sqlProcSuccess" && \
   Print_Output true "Database analysis and optimization completed successfully." "$PASS"

   renice 0 $$
}

##-------------------------------------##
## Added by Martinski W. [2025-Feb-28] ##
##-------------------------------------##
_Trim_Database_()
{
   renice 15 $$
   TZ="$(cat /etc/TZ)"
   export TZ
   timeNow="$(date +'%s')"

   local foundError  foundLocked  resultStr  SQLTable  sqlProcSuccess

   Print_Output true "Trimming records from database..." "$PASS"

   sqlProcSuccess=true
   local trmIndx=0
   for dbtable in $FULL_IFACELIST
   do
       SQLTable="spdstats_$dbtable"
       {
          echo "PRAGMA temp_store=1;"
          echo "PRAGMA journal_mode=TRUNCATE;"
          echo "PRAGMA cache_size=-20000;"
          echo "DELETE FROM [$SQLTable] WHERE [Timestamp] < strftime('%s',datetime($timeNow,'unixepoch','-$(DaysToKeep check) day'));"
       } > /tmp/spdMerlin-trim.sql
       trmIndx="$((trmIndx + 1))"
       _ApplyDatabaseSQLCmds_ /tmp/spdMerlin-trim.sql "trm$trmIndx"

       rm -f /tmp/spdMerlin-trim.sql
       if "$foundError" || "$foundLocked"
       then
           sqlProcSuccess=false
           Print_Output true "Database [$SQLTable] record trimming ${resultStr}" "$ERR"
       fi
   done

   "$sqlProcSuccess" && \
   Print_Output true "Database record trimming completed successfully." "$PASS"

   renice 0 $$
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
Run_Speedtest()
{
	if [ ! -f /opt/bin/xargs ] && [ -x /opt/bin/opkg ]
	then
		Print_Output true "Installing findutils from Entware"
		opkg update
		opkg install findutils
	fi
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME_LOWER" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME_LOWER" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi
	Create_Dirs
	Conf_Exists
	if [ "$(SpeedtestBinary check)" = "builtin" ]
	then
		printf "/usr/sbin/ookla" > /tmp/spdmerlin-binary
	elif [ "$(SpeedtestBinary check)" = "external" ]
	then
		printf "%s" "$OOKLA_DIR/speedtest" > /tmp/spdmerlin-binary
	fi
	Auto_Startup create 2>/dev/null
	if AutomaticMode check
	then Auto_Cron create 2>/dev/null
	else Auto_Cron delete 2>/dev/null
	fi
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	ScriptStorageLocation load
	Create_Symlinks

	mode="$1"
	if [ $# -lt 2 ] || [ -z "$2" ]
	then specificiface=""
	else specificiface="$2"
	fi
	speedtestServerIDx=""
	speedtestServerName=""
	MAXwaitTestSecs=120  #2 minutes#
	local spdIndx  spdTestOK  verboseNUM  verboseARG
	verboseNUM="$(_GetConfigParam_ VERBOSE_TEST 0)"
	if ! echo "$verboseNUM" | grep -qE "^[0-3]$"
	then verboseNUM=0
	fi

	CONFIG_STRING=""
	LICENSE_STRING="--accept-license --accept-gdpr"
	PROC_NAME="speedtest"
	SPEEDTEST_BINARY=""
	if [ "$(SpeedtestBinary check)" = "builtin" ]
	then
		SPEEDTEST_BINARY=/usr/sbin/ookla
	elif [ "$(SpeedtestBinary check)" = "external" ]
	then
		SPEEDTEST_BINARY="$OOKLA_DIR/speedtest"
	fi
	if [ "$SPEEDTEST_BINARY" = "/usr/sbin/ookla" ]
	then
		CONFIG_STRING="-c http://www.speedtest.net/api/embed/vz0azjarf5enop8a/config"
		LICENSE_STRING=""
		PROC_NAME="ookla"
	fi

	echo 'var spdteststatus = "InProgress";' > /tmp/detect_spdtest.js

	tmpfile=/tmp/spd-stats.txt
	resultfile=/tmp/spd-result.txt
	spdTestLogFile="/tmp/${SCRIPT_NAME}.DEBUG.log"
	spdTestDBGFile="/tmp/${SCRIPT_NAME}.DEBUG.txt"
	rm -f "$tmpfile" "$resultfile" "$spdTestLogFile"

	if [ -n "$(pidof "$PROC_NAME")" ]; then
		killall -q "$PROC_NAME"
	fi

	if Check_Swap
	then
		IFACELIST=""
		if [ -z "$specificiface" ]
		then
			while IFS='' read -r line || [ -n "$line" ]
			do
				if [ "$(echo "$line" | grep -c "#")" -eq 0 ]; then
					IFACELIST="$IFACELIST $(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				fi
			done < "$SCRIPT_INTERFACES_USER"
			IFACELIST="$(echo "$IFACELIST" | cut -c2-)"
		elif [ "$specificiface" = "All" ]
		then
			while IFS='' read -r line || [ -n "$line" ]
			do
				if [ "$(echo "$line" | grep -c "interface not up")" -eq 0 ]; then
					IFACELIST="$IFACELIST $(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				fi
			done < "$SCRIPT_INTERFACES_USER"
			IFACELIST="$(echo "$IFACELIST" | cut -c2-)"
		else
			IFACELIST="$specificiface"
		fi

		if [ "$IFACELIST" != "" ]
		then
			stoppedqos="false"
			if [ "$(ExcludeFromQoS check)" = "true" ]
			then
				if [ "$(nvram get qos_enable)" -eq 1 ] && [ "$(nvram get qos_type)" -eq 1 ]
				then
					for ACTION in -D -A
					do
						for proto in tcp udp
						do
							iptables "$ACTION" OUTPUT -p "$proto" -o "$(Get_Interface_From_Name WAN)" -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
							iptables "$ACTION" OUTPUT -p "$proto" -o tun1+ -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
							iptables -t mangle "$ACTION" OUTPUT -p "$proto" -o "$(Get_Interface_From_Name WAN)" -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
							iptables -t mangle "$ACTION" OUTPUT -p "$proto" -o tun1+ -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
						done
						stoppedqos="true"
					done
				elif [ "$(nvram get qos_enable)" -eq 1 ] && [ "$(nvram get qos_type)" -ne 1 ] && [ -f /tmp/qos ]
				then
					/tmp/qos stop >/dev/null 2>&1
					stoppedqos="true"
				elif [ "$(nvram get qos_enable)" -eq 0 ] && [ -f /jffs/addons/cake-qos/cake-qos ]
				then
					/jffs/addons/cake-qos/cake-qos stop >/dev/null 2>&1
					stoppedqos="true"
				fi
			fi

			applyautobw="false"
			if [ "$mode" = "schedule" ] && [ "$(AutoBWEnable check)" = "true" ]; then
				applyautobw="true"
			fi

			if [ "$verboseNUM" -eq 0 ]
			then verboseARG=""
			else verboseARG="$(printf "-%*s" "$((verboseNUM + 1))" ' ' | tr ' ' 'v')"
			fi
			spdIndx=0  spdTestOK=0

			for IFACE_NAME in $IFACELIST
			do
				IFACE="$(Get_Interface_From_Name "$IFACE_NAME")"
				IFACE_LOWER="$(echo "$IFACE" | tr "A-Z" "a-z")"

				interface_UP=false
				if echo "$IFACE_NAME" | grep -q "^WGVPN"
				then 
				    if _Check_WG_ClientInterfaceUP_ "$IFACE_LOWER"
				    then interface_UP=true ; fi
				else
				    if _CheckNetClientInterfaceUP_ "$IFACE_LOWER"
				    then interface_UP=true ; fi
				fi

				if ! "$interface_UP"
				then
					Print_Output true "$IFACE not up, please check. Skipping speedtest for $IFACE_NAME" "$WARN"
					continue
				else
					if [ "$mode" = "webui_user" ]; then
						mode="user"
					elif [ "$mode" = "webui_auto" ]; then
						mode="auto"
					elif [ "$mode" = "webui_onetime" ]; then
						mode="user"
					fi

					if [ "$mode" = "schedule" ]
					then
						if PreferredServer check "$IFACE_NAME"
						then
							speedtestServerIDx="$(PreferredServer list "$IFACE_NAME" | cut -f1 -d"|")"
							speedtestServerName="$(PreferredServer list "$IFACE_NAME" | cut -f2 -d"|")"
						else
							mode="auto"
						fi
					elif [ "$mode" = "onetime" ]
					then
						GenerateServerList "$IFACE_NAME" no
						if [ "$serverno" != "exit" ]; then
							speedtestServerIDx="$serverno"
							speedtestServerName="$servername"
						else
							Clear_Lock
							return 1
						fi
					elif [ "$mode" = "user" ]
					then
						speedtestServerIDx="$(PreferredServer list "$IFACE_NAME" | cut -f1 -d"|")"
						speedtestServerName="$(PreferredServer list "$IFACE_NAME" | cut -f2 -d"|")"
					fi

					echo 'var spdteststatus = "InProgress_'"$IFACE_NAME"'";' > /tmp/detect_spdtest.js
					printf "" > "$tmpfile"
					
					if [ "$mode" = "auto" ]
					then
						Print_Output true "Starting speedtest using auto-selected server for $IFACE_NAME interface. Please wait..." "$PASS"
						"$SPEEDTEST_BINARY" $verboseARG $CONFIG_STRING --interface="$IFACE" --format="human-readable" --unit="Mbps" -p $LICENSE_STRING 2>"$spdTestLogFile" | tee "$tmpfile" &
						sleep 2
						speedTestSecs=0
						while [ -n "$(pidof "$PROC_NAME")" ] && [ "$speedTestSecs" -lt "$MAXwaitTestSecs" ]
						do
							speedTestSecs="$((speedTestSecs + 1))" ; sleep 1
						done
						if [ "$speedTestSecs" -ge "$MAXwaitTestSecs" ]
						then
							Print_Output true "Speedtest for $IFACE_NAME hung (> 2 mins), killing process" "$CRIT"
							killall -q "$PROC_NAME"
							if [ -s "$spdTestLogFile" ] ; then echo ; cat "$spdTestLogFile" ; echo ; fi
							continue
						fi
					else
						if [ "$speedtestServerIDx" -ne 0 ]
						then
							Print_Output true "Starting speedtest using $speedtestServerName for $IFACE_NAME interface. Please wait..." "$PASS"
							"$SPEEDTEST_BINARY" $verboseARG $CONFIG_STRING --interface="$IFACE" --server-id="$speedtestServerIDx" --format="human-readable" --unit="Mbps" -p $LICENSE_STRING 2>"$spdTestLogFile" | tee "$tmpfile" &
							sleep 2
							speedTestSecs=0
							while [ -n "$(pidof "$PROC_NAME")" ] && [ "$speedTestSecs" -lt "$MAXwaitTestSecs" ]
							do
								speedTestSecs="$((speedTestSecs + 1))" ; sleep 1
							done
							if [ "$speedTestSecs" -ge "$MAXwaitTestSecs" ]
							then
								Print_Output true "Speedtest for $IFACE_NAME hung (> 2 mins), killing process" "$CRIT"
								killall -q "$PROC_NAME"
								if [ -s "$spdTestLogFile" ] ; then echo ; cat "$spdTestLogFile" ; echo ; fi
								continue
							fi
						else
							Print_Output true "Starting speedtest using using auto-selected server for $IFACE_NAME interface. Please wait..." "$PASS"
							"$SPEEDTEST_BINARY" $verboseARG $CONFIG_STRING --interface="$IFACE" --format="human-readable" --unit="Mbps" -p $LICENSE_STRING 2>"$spdTestLogFile" | tee "$tmpfile" &
							sleep 2
							speedTestSecs=0
							while [ -n "$(pidof "$PROC_NAME")" ] && [ "$speedTestSecs" -lt "$MAXwaitTestSecs" ]
							do
								speedTestSecs="$((speedTestSecs + 1))" ; sleep 1
							done
							if [ "$speedTestSecs" -ge "$MAXwaitTestSecs" ]
							then
								Print_Output true "Speedtest for $IFACE_NAME hung (> 2 mins), killing process" "$CRIT"
								killall -q "$PROC_NAME"
								if [ -s "$spdTestLogFile" ] ; then echo ; cat "$spdTestLogFile" ; echo ; fi
								continue
							fi
						fi
					fi

					if [ ! -s "$tmpfile" ] || [ -z "$(cat "$tmpfile")" ] || [ "$(grep -c 'FAILED' "$tmpfile")" -gt 0 ]
					then
						Print_Output true "ERROR running speedtest for $IFACE_NAME [No Results]" "$CRIT"
						if [ -s "$spdTestLogFile" ] ; then echo ; cat "$spdTestLogFile" ; echo ; fi
						continue
					fi

					ScriptStorageLocation load

					TZ="$(cat /etc/TZ)"
					export TZ

					timenow="$(date +'%s')"
					timenowfriendly="$(date +'%c')"

					## New if-then-else block added to with ookla output when buffer bloat has been added to the human readable output ##
					BUFFBLOAT="$(grep "Idle Latency:" "$tmpfile")"
					if [ -n "$BUFFBLOAT" ]
					then
						# Parse human readable output when buffer bloat data is included.#
						download="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $2}')"
						upload="$(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $2}')"						
      
						latency="$(grep "Idle Latency:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $3}')"
						jitter="$(grep "Idle Latency:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $6}' | tr -d 'ms,')"
						pktloss="$(grep "Packet Loss:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $3}' | tr -d '%')"
						resulturl="$(grep "Result URL:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $3}')"
						datadownload="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $6}')"
						dataupload="$(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $6}')"

						datadownloadunit="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print substr($7,1,length($7)-1)}')"
						datauploadunit="$(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print substr($7,1,length($7)-1)}')"

						servername="$(grep "Server:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | cut -f1 -d'(' | cut -f2 -d':' | awk '{$1=$1;print}')"
						serverid="$(grep "Server:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | cut -f2 -d'(' | awk '{print $2}' | tr -d ')')"
					else
						download="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $2}')"
						upload="$(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $2}')"						
      
						latency="$(grep "Latency:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $2}')"
						jitter="$(grep "Latency:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $4}' | tr -d '(')"
						pktloss="$(grep "Packet Loss:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $3}' | tr -d '%')"
						resulturl="$(grep "Result URL:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $3}')"
						datadownload="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $6}')"
						dataupload="$(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print $6}')"

						datadownloadunit="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print substr($7,1,length($7)-1)}')"
						datauploadunit="$(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{print substr($7,1,length($7)-1)}')"

						servername="$(grep "Server:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | cut -f1 -d'(' | cut -f2 -d':' | awk '{$1=$1;print}')"
						serverid="$(grep "Server:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | cut -f2 -d'(' | awk '{print $3}' | tr -d ')')"
					fi

     					# convert to Mbps if necessary
					if [ "$datadownloadunit" = "kB" ]; then
						datadownload=$(awk "BEGIN { printf \"%.3f\", $datadownload/1000 }")
					fi

					if [ "$datauploadunit" = "kB" ]; then
						dataupload=$(awk "BEGIN { printf \"%.3f\", $dataupload/1000 }")
					fi

					if [ -z "$download" ] || [ -z "$upload" ] || [ -z "$datadownload" ] || [ -z "$dataupload" ]
					then
						cp -fp "$tmpfile" "$spdTestDBGFile"
						Print_Output true "ERROR running speedtest for $IFACE_NAME [Empty Values]" "$CRIT"
						if [ -s "$spdTestLogFile" ] ; then echo ; cat "$spdTestLogFile" ; echo ; fi
						continue
					fi

					! Validate_Bandwidth "$download" && download=0;
					! Validate_Bandwidth "$upload" && upload=0;
					! Validate_Bandwidth "$latency" && latency="null";
					! Validate_Bandwidth "$jitter" && jitter="null";
					! Validate_Bandwidth "$pktloss" && pktloss="null";
					! Validate_Bandwidth "$datadownload" && datadownload=0;
					! Validate_Bandwidth "$dataupload" && dataupload=0;

					if [ "$datadownloadunit" = "GB" ]; then
						datadownload="$(echo "$datadownload" | awk '{printf ($1*1024)}')"
					fi

					if [ "$datauploadunit" = "GB" ]; then
						dataupload="$(echo "$dataupload" | awk '{printf ($1*1024)}')"
					fi

					if [ "$(SpeedtestBinary check)" = "builtin" ]
					then
						curllatency="$latency"
						if [ "$curllatency" = "null" ]; then
							curllatency=0
						fi

						curlresult=$(curl -fsL  --retry 4 --retry-delay 5 -d "recommendedserverid=$serverid" \
-d "ping=$(echo "$curllatency" | awk '{printf("%.0f\n", $1);}')" \
-d "screenresolution=" \
-d "promo=" \
-d "download=$(echo "$download" | awk '{printf("%.0f\n", $1*1000);}')" \
-d "screendpi=" \
-d "upload=$(echo "$upload" | awk '{printf("%.0f\n", $1*1000);}')" \
-d "testmethod=http" \
-d "hash=$(printf "$(echo "$curllatency" | awk '{printf("%.0f\n", $1);}')-$(echo "$upload" | awk '{printf("%.0f\n", $1*1000);}')-$(echo "$download" | awk '{printf("%.0f\n", $1*1000);}')-297aae72" | md5sum | cut -f1 -d' ')" \
-d "touchscreen=none" \
-d "startmode=pingselect" \
-d "accuracy=1" \
-d "bytesreceived=$(echo "$datadownload" | awk '{printf("%.0f\n", $1*1024);}')" \
-d "bytessent=$(echo "$dataupload" | awk '{printf("%.0f\n", $1*1024);}')" \
-d "serverid=$serverid" \
-H "Referer: http://c.speedtest.net/flash/speedtest.swf" https://www.speedtest.net/api/api.php)

						resulturl="https://www.speedtest.net/result/$(echo "$curlresult" | cut -f2 -d'&' | cut -f2 -d'=')"
						printf " Result URL: %s\n" "$resulturl" | tee -a "$tmpfile"
					fi

					spdIndx="$((spdIndx + 1))"
					{
					   echo "PRAGMA temp_store=1;"
					   echo "PRAGMA journal_mode=TRUNCATE;"
					   echo "CREATE TABLE IF NOT EXISTS [spdstats_$IFACE_NAME] ([StatID] INTEGER PRIMARY KEY NOT NULL,[Timestamp] NUMERIC NOT NULL,[Download] REAL NOT NULL,[Upload] REAL NOT NULL,[Latency] REAL,[Jitter] REAL,[PktLoss] REAL,[ResultURL] TEXT,[DataDownload] REAL NOT NULL,[DataUpload] REAL NOT NULL,[ServerID] TEXT,[ServerName] TEXT);"
					} > /tmp/spdTest-stats.sql
					_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "spd1$spdIndx"

					STORERESULTURL="$(StoreResultURL check)"

					if [ "$STORERESULTURL" = "true" ]
					then
						{
						   echo "PRAGMA temp_store=1;"
						   echo "INSERT INTO spdstats_$IFACE_NAME ([Timestamp],[Download],[Upload],[Latency],[Jitter],[PktLoss],[ResultURL],[DataDownload],[DataUpload],[ServerID],[ServerName]) values($timenow,$download,$upload,$latency,$jitter,$pktloss,'$resulturl',$datadownload,$dataupload,$serverid,'$servername');"
						} > /tmp/spdTest-stats.sql
					elif [ "$STORERESULTURL" = "false" ]
					then
						{
						   echo "PRAGMA temp_store=1;"
						   echo "INSERT INTO spdstats_$IFACE_NAME ([Timestamp],[Download],[Upload],[Latency],[Jitter],[PktLoss],[ResultURL],[DataDownload],[DataUpload],[ServerID],[ServerName]) values($timenow,$download,$upload,$latency,$jitter,$pktloss,'',$datadownload,$dataupload,$serverid,'$servername');"
						} > /tmp/spdTest-stats.sql
					fi
					_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "spd2$spdIndx"

					spdtestresult1="$(grep "Download:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};'| awk '{$1=$1};1') - $(grep "Upload:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};'| awk '{$1=$1};1')"
					spdtestresult2="$(grep "Latency:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{$1=$1};1') - $(grep "Packet Loss:" "$tmpfile" | awk 'BEGIN { FS = "\r" } ;{print $NF};' | awk '{$1=$1};1')"

					printf "\n$(date +'%c')\n"
					Print_Output true "Speedtest results - $spdtestresult1" "$PASS"
					Print_Output true "Connection quality - $spdtestresult2" "$PASS"

					{
						printf "Speedtest result for %s [%s]\n\n" "$IFACE_NAME" "$(date +'%c')"
						printf "BANDWIDTH\n%s\n" "$spdtestresult1"
						printf "QUALITY\n%s\n\n" "$spdtestresult2"
						grep "Result URL" "$tmpfile" | awk '{$1=$1};1'
						printf "\n\n\n"
					} >> "$resultfile"

					spdTestOK="$((spdTestOK + 1))"
					extStats="/jffs/addons/extstats.d/mod_spdstats.sh"
					if [ -f "$extStats" ]; then
						sh "$extStats" ext "$download" "$upload"
					fi
				fi
			done

			if [ "$stoppedqos" = "true" ]
			then
				if [ "$(nvram get qos_enable)" -eq 1 ] && [ "$(nvram get qos_type)" -eq 1 ]
				then
					for proto in tcp udp
					do
						iptables -D OUTPUT -p "$proto" -o "$(Get_Interface_From_Name WAN)" -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
						iptables -D OUTPUT -p "$proto" -o tun1+ -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
						iptables -t mangle -D OUTPUT -p "$proto" -o "$(Get_Interface_From_Name WAN)" -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
						iptables -t mangle -D OUTPUT -p "$proto" -o tun1+ -j MARK --set-xmark 0x80000000/0xC0000000 2>/dev/null
					done
				elif [ "$(nvram get qos_enable)" -eq 1 ] && [ "$(nvram get qos_type)" -ne 1 ] && [ -f /tmp/qos ]
				then
					/tmp/qos start >/dev/null 2>&1
				elif [ "$(nvram get qos_enable)" -eq 0 ] && [ -f /jffs/addons/cake-qos/cake-qos ]
				then
					/jffs/addons/cake-qos/cake-qos start >/dev/null 2>&1
				fi
			fi

			if [ "$spdTestOK" -gt 0 ]
			then
				echo 'var spdteststatus = "GenerateCSV";' > /tmp/detect_spdtest.js
				Print_Output true "Retrieving data for WebUI charts..." "$PASS"
				Generate_CSVs

				echo "Stats last updated: $timenowfriendly" > /tmp/spdstatstitle.txt
				WriteStats_ToJS /tmp/spdstatstitle.txt "$SCRIPT_STORAGE_DIR/spdtitletext.js" SetSPDStatsTitle statstitle
			fi
			_UpdateDatabaseFileSizeInfo_

			if [ "$applyautobw" = "true" ]; then
				Menu_AutoBW_Update
			fi

			rm -f "$tmpfile"
			rm -f /tmp/spdstatstitle.txt

			echo 'var spdteststatus = "Done";' > /tmp/detect_spdtest.js

			Clear_Lock
		else
			echo 'var spdteststatus = "Error";' > /tmp/detect_spdtest.js
			Print_Output true "No interfaces enabled, exiting" "$CRIT"
			Clear_Lock
			return 1
		fi
		Clear_Lock
	else
		echo 'var spdteststatus = "NoSwap";' > /tmp/detect_spdtest.js
		Print_Output true "Swap file not active, exiting" "$CRIT"
		Clear_Lock
		return 1
	fi
}

Run_Speedtest_WebUI()
{
	spdteststring="$(echo "$1" | sed "s/${SCRIPT_NAME_LOWER}spdtest_//;s/%/ /g")";
	spdtestmode="webui_$(echo "$spdteststring" | cut -f1 -d'_')";
	spdifacename="$(echo "$spdteststring" | cut -f2 -d'_')";

	cp -a "$SCRIPT_CONF" "${SCRIPT_CONF}.bak"

	if [ "$spdtestmode" = "webui_onetime" ]
	then
		spdtestserverlist="$(echo "$spdteststring" | cut -f3 -d'_')";
		if [ "$spdifacename" = "All" ]
		then
			IFACELIST=""
			while IFS='' read -r line || [ -n "$line" ]
			do
				if [ "$(echo "$line" | grep -c "interface not up")" -eq 0 ]
				then
					IFACELIST="$IFACELIST $(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				fi
			done < "$SCRIPT_INTERFACES_USER"
			IFACELIST="$(echo "$IFACELIST" | cut -c2-)"
			
			COUNT=1
			for IFACE_NAME in $IFACELIST
			do
				spdtestserver="$(grep -m1 "$(echo "$spdtestserverlist" | cut -f"$COUNT" -d'+')" /tmp/spdmerlin_manual_serverlist.txt)"
				sed -i 's/^PREFERREDSERVER_'"$IFACE_NAME"'=.*$/PREFERREDSERVER_'"$IFACE_NAME"'='"$spdtestserver"'/' "$SCRIPT_CONF"
				COUNT="$((COUNT+1))"
			done
		else
			spdtestserver="$(grep -m1 "$spdtestserverlist" /tmp/spdmerlin_manual_serverlist.txt)"
			sed -i 's/^PREFERREDSERVER_'"$spdifacename"'=.*$/PREFERREDSERVER_'"$spdifacename"'='"$spdtestserver"'/' "$SCRIPT_CONF"
		fi
	fi
	sleep 1
	Run_Speedtest "$spdtestmode" "$spdifacename"
	cp -a "${SCRIPT_CONF}.bak" "$SCRIPT_CONF"
}

##-------------------------------------##
## Added by Martinski W. [2025-Jun-02] ##
##-------------------------------------##
_FindTableColumnTextInDatabase_()
{
   if [ $# -lt 3 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
   then return 1 ; fi

   local retCode
   local IFACE_ID="$1"
   local tableInfoFileSQL="/tmp/spdstats-tableinfo.sql"
   local tableInfoFileLST="/tmp/spdstats-tableinfo.lst"

   {
      echo ".mode list"
      echo ".headers off"
      echo ".separator '|'"
      echo ".output $tableInfoFileLST"
      echo "PRAGMA temp_store=1;"
      echo "PRAGMA cache_size=-20000;"
      echo "PRAGMA table_info(spdstats_${IFACE_ID});"
   } > "$tableInfoFileSQL"
   _ApplyDatabaseSQLCmds_ "$tableInfoFileSQL" "ftc$3"

   if grep -q "|${2}|TEXT|" "$tableInfoFileLST"
   then
       retCode=0
   else
       retCode=1
   fi

   rm -f "$tableInfoFileSQL" "$tableInfoFileLST"
   return "$retCode"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-02] ##
##----------------------------------------##
Process_Upgrade()
{
	local foundError  foundLocked  resultStr  doUpdateDB=false

	if [ ! -f "$OOKLA_DIR/speedtest" ]
	then
		Download_File "$SCRIPT_REPO/$ARCH.tar.gz" "$OOKLA_DIR/$ARCH.tar.gz"
		tar -xzf "$OOKLA_DIR/$ARCH.tar.gz" -C "$OOKLA_DIR"
		rm -f "$OOKLA_DIR/$ARCH.tar.gz"
		chmod 0755 "$OOKLA_DIR/speedtest"
	fi
	rm -f "$SCRIPT_STORAGE_DIR/spdjs.js"
	rm -f "$SCRIPT_STORAGE_DIR/.tableupgraded"*

	if [ ! -f "$SCRIPT_DIR/README.md" ]; then
		Update_File README.md
	fi
	if [ ! -f "$SCRIPT_DIR/LICENSE" ]; then
		Update_File LICENSE
	fi
	if [ "$(AutoBWEnable check)" = "true" ]
	then
		if [ "$(ExcludeFromQoS check)" = "false" ]
		then
			Print_Output false "Enabling Exclude from QoS (required for AutoBW)"
			ExcludeFromQoS enable
		fi
	fi

	local prcIndx=0
	for IFACE_NAME in $FULL_IFACELIST
	do
		{
		   echo "PRAGMA temp_store=1;"
		   echo "PRAGMA journal_mode=TRUNCATE;"
		   echo "CREATE TABLE IF NOT EXISTS [spdstats_$IFACE_NAME] ([StatID] INTEGER PRIMARY KEY NOT NULL,[Timestamp] NUMERIC NOT NULL,[Download] REAL NOT NULL,[Upload] REAL NOT NULL,[Latency] REAL,[Jitter] REAL,[PktLoss] REAL,[ResultURL] TEXT,[DataDownload] REAL NOT NULL,[DataUpload] REAL NOT NULL,[ServerID] TEXT,[ServerName] TEXT);"
		} > /tmp/spdstats-upgrade.sql
		prcIndx="$((prcIndx + 1))"
		_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc01$prcIndx"
		if ! "$foundError" && ! "$foundLocked" ; then doUpdateDB=true ; fi
	done

	if [ ! -f "$SCRIPT_STORAGE_DIR/.databaseupgraded" ]
	then
		renice 15 $$
		Print_Output true "Upgrading database - Please wait..." "$PASS"

		prcIndx=0
		for IFACE_NAME in $FULL_IFACELIST
		do
			prcIndx="$((prcIndx + 1))"
			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_download ON spdstats_${IFACE_NAME} (Timestamp,Download);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc02$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_upload ON spdstats_${IFACE_NAME} (Timestamp,Upload);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc03$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_latency ON spdstats_${IFACE_NAME} (Timestamp,Latency);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc04$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_jitter ON spdstats_${IFACE_NAME} (Timestamp,Jitter);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc05$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_pktloss ON spdstats_${IFACE_NAME} (Timestamp,PktLoss);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc06$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_resulturl ON spdstats_${IFACE_NAME} (Timestamp,ResultURL collate nocase);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc07$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_datadownload ON spdstats_${IFACE_NAME} (Timestamp,DataDownload);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc08$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_datadownload ON spdstats_${IFACE_NAME} (Timestamp,DataUpload);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc09$prcIndx"

			if ! _FindTableColumnTextInDatabase_ "$IFACE_NAME" "ServerID" "10$prcIndx"
			then
				{
				   echo "PRAGMA temp_store=1;"
				   echo "PRAGMA cache_size=-20000;"
				   echo "ALTER TABLE spdstats_${IFACE_NAME} ADD COLUMN [ServerID] TEXT"
				} > /tmp/spdstats-upgrade.sql
				_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc10$prcIndx"
			fi

			if ! _FindTableColumnTextInDatabase_ "$IFACE_NAME" "ServerName" "11$prcIndx"
			then
				{
				   echo "PRAGMA temp_store=1;"
				   echo "PRAGMA cache_size=-20000;"
				   echo "ALTER TABLE spdstats_${IFACE_NAME} ADD COLUMN [ServerName] TEXT"
				} > /tmp/spdstats-upgrade.sql
				_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc11$prcIndx"
			fi

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_serverid ON spdstats_${IFACE_NAME} (Timestamp,ServerID);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc12$prcIndx"

			{
			   echo "PRAGMA temp_store=1;"
			   echo "PRAGMA cache_size=-20000;"
			   echo "CREATE INDEX IF NOT EXISTS idx_${IFACE_NAME}_servername ON spdstats_${IFACE_NAME} (Timestamp,ServerName collate nocase);"
			} > /tmp/spdstats-upgrade.sql
			_ApplyDatabaseSQLCmds_ /tmp/spdstats-upgrade.sql "prc13$prcIndx"

			Generate_LastXResults "$IFACE_NAME" "$prcIndx"
		done

		touch "$SCRIPT_STORAGE_DIR/.databaseupgraded"
		Generate_CSVs
		Print_Output true "Database ready, continuing..." "$PASS"
		renice 0 $$
		doUpdateDB=true
	fi

	if [ ! -f "$SCRIPT_STORAGE_DIR/spdtitletext.js" ]
	then
		doUpdateDB=true
		echo "Stats last updated: Not yet updated" > /tmp/spdstatstitle.txt
		WriteStats_ToJS /tmp/spdstatstitle.txt "$SCRIPT_STORAGE_DIR/spdtitletext.js" SetSPDStatsTitle statstitle
	fi

	rm -f /tmp/spdstats-upgrade.sql
	"$doUpdateDB" && _UpdateDatabaseFileSizeInfo_
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
#$1 IFACE Name
Generate_LastXResults()
{
	for IFACE_NAME in $FULL_IFACELIST;
    do
		rm -f "$SCRIPT_STORAGE_DIR/lastx_${IFACE_NAME}.htm"
	done

	local glxIndx=0
	if [ $# -gt 1 ] && [ -n "$2" ] ; then glxIndx="$2" ; fi

	{
	   echo ".mode csv"
	   echo ".output /tmp/spdMerlin-lastx.csv"
	   echo "PRAGMA temp_store=1;"
	   echo "SELECT [Timestamp],[Download],[Upload],[Latency],[Jitter],[PktLoss],[DataDownload],[DataUpload],[ResultURL],[ServerID],[ServerName] FROM spdstats_$1 ORDER BY [Timestamp] DESC LIMIT $(LastXResults check);" 
    } > /tmp/spdMerlin-lastx.sql
	_ApplyDatabaseSQLCmds_ /tmp/spdMerlin-lastx.sql "glx$glxIndx"

	rm -f /tmp/spdMerlin-lastx.sql
	sed -i 's/,,/,null,/g;s/"//g;' /tmp/spdMerlin-lastx.csv
	mv -f /tmp/spdMerlin-lastx.csv "$SCRIPT_STORAGE_DIR/lastx_${1}.csv"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Generate_CSVs()
{
    local gnrIndx1=0  gnrIndx2=0

	Process_Upgrade
	renice 15 $$

	OUTPUTTIMEMODE="$(OutputTimeMode check)"
	STORERESULTURL="$(StoreResultURL check)"
	IFACELIST=""

	while IFS='' read -r line || [ -n "$line" ]
	do
		IFACELIST="$IFACELIST $(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
	done < "$SCRIPT_INTERFACES_USER"
	IFACELIST="$(echo "$IFACELIST" | cut -c2-)"

	if [ "$IFACELIST" != "" ]
	then
        gnrIndx1=0
		for IFACE_NAME in $IFACELIST
		do
			gnrIndx1="$((gnrIndx1 + 1))"
			IFACE="$(Get_Interface_From_Name "$IFACE_NAME")"

			TZ="$(cat /etc/TZ)"
			export TZ

			timenow="$(date +'%s')"
			timenowfriendly="$(date +'%c')"

			metriclist="Download Upload Latency Jitter PktLoss" # DataDownload DataUpload"
			gnrIndx2=0

			for metric in $metriclist
			do
				gnrIndx2="$((gnrIndx2 + 1))"
				{
				   echo ".mode csv"
				   echo ".headers off"
				   echo ".output $CSV_OUTPUT_DIR/${metric}_raw_daily_$IFACE_NAME.tmp"
				   echo "PRAGMA temp_store=1;"
				   echo "SELECT '$metric' Metric,[Timestamp] Time,[$metric] Value FROM spdstats_$IFACE_NAME WHERE ([Timestamp] >= strftime('%s',datetime($timenow,'unixepoch','-1 day'))) ORDER BY [Timestamp] DESC;"
				} > /tmp/spdTest-stats.sql
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr1${gnrIndx1}${gnrIndx2}"

				{
				   echo ".mode csv"
				   echo ".headers off"
				   echo ".output $CSV_OUTPUT_DIR/${metric}_raw_weekly_$IFACE_NAME.tmp"
				   echo "PRAGMA temp_store=1;"
				   echo "SELECT '$metric' Metric,[Timestamp] Time,[$metric] Value FROM spdstats_$IFACE_NAME WHERE ([Timestamp] >= strftime('%s',datetime($timenow,'unixepoch','-7 day'))) ORDER BY [Timestamp] DESC;"
				} > /tmp/spdTest-stats.sql
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr2${gnrIndx1}${gnrIndx2}"

				{
				   echo ".mode csv"
				   echo ".headers off"
				   echo ".output $CSV_OUTPUT_DIR/${metric}_raw_monthly_$IFACE_NAME.tmp"
				   echo "PRAGMA temp_store=1;"
				   echo "SELECT '$metric' Metric,[Timestamp] Time,[$metric] Value FROM spdstats_$IFACE_NAME WHERE ([Timestamp] >= strftime('%s',datetime($timenow,'unixepoch','-30 day'))) ORDER BY [Timestamp] DESC;"
				} > /tmp/spdTest-stats.sql
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr3${gnrIndx1}${gnrIndx2}"

				WriteSql_ToFile "$metric" "spdstats_$IFACE_NAME" 1 1 "$CSV_OUTPUT_DIR/${metric}_hour" daily "$IFACE_NAME" /tmp/spdTest-stats.sql "$timenow"
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr4${gnrIndx1}${gnrIndx2}"

				WriteSql_ToFile "$metric" "spdstats_$IFACE_NAME" 1 7 "$CSV_OUTPUT_DIR/${metric}_hour" weekly "$IFACE_NAME" /tmp/spdTest-stats.sql "$timenow"
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr5${gnrIndx1}${gnrIndx2}"

				WriteSql_ToFile "$metric" "spdstats_$IFACE_NAME" 1 30 "$CSV_OUTPUT_DIR/${metric}_hour" monthly "$IFACE_NAME" /tmp/spdTest-stats.sql "$timenow"
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr6${gnrIndx1}${gnrIndx2}"

				WriteSql_ToFile "$metric" "spdstats_$IFACE_NAME" 24 1 "$CSV_OUTPUT_DIR/${metric}_day" daily "$IFACE_NAME" /tmp/spdTest-stats.sql "$timenow"
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr7${gnrIndx1}${gnrIndx2}"

				WriteSql_ToFile "$metric" "spdstats_$IFACE_NAME" 24 7 "$CSV_OUTPUT_DIR/${metric}_day" weekly "$IFACE_NAME" /tmp/spdTest-stats.sql "$timenow"
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr8${gnrIndx1}${gnrIndx2}"

				WriteSql_ToFile "$metric" "spdstats_$IFACE_NAME" 24 30 "$CSV_OUTPUT_DIR/${metric}_day" monthly "$IFACE_NAME" /tmp/spdTest-stats.sql "$timenow"
				_ApplyDatabaseSQLCmds_ /tmp/spdTest-stats.sql "gnr9${gnrIndx1}${gnrIndx2}"
			done

			periodfilelist="raw hour day"

			for periodfile in $periodfilelist
			do
				cat "$CSV_OUTPUT_DIR/Download_${periodfile}_daily_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/Upload_${periodfile}_daily_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/Combined_${periodfile}_daily_${IFACE_NAME}.htm" 2> /dev/null
				cat "$CSV_OUTPUT_DIR/Download_${periodfile}_weekly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/Upload_${periodfile}_weekly_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/Combined_${periodfile}_weekly_${IFACE_NAME}.htm" 2> /dev/null
				cat "$CSV_OUTPUT_DIR/Download_${periodfile}_monthly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/Upload_${periodfile}_monthly_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/Combined_${periodfile}_monthly_${IFACE_NAME}.htm" 2> /dev/null
				
				cat "$CSV_OUTPUT_DIR/Latency_${periodfile}_daily_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/Jitter_${periodfile}_daily_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/PktLoss_${periodfile}_daily_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/Quality_${periodfile}_daily_${IFACE_NAME}.htm" 2> /dev/null
				cat "$CSV_OUTPUT_DIR/Latency_${periodfile}_weekly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/Jitter_${periodfile}_weekly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/PktLoss_${periodfile}_weekly_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/Quality_${periodfile}_weekly_${IFACE_NAME}.htm" 2> /dev/null
				cat "$CSV_OUTPUT_DIR/Latency_${periodfile}_monthly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/Jitter_${periodfile}_monthly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/PktLoss_${periodfile}_monthly_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/Quality_${periodfile}_monthly_${IFACE_NAME}.htm" 2> /dev/null
				
				#cat "$CSV_OUTPUT_DIR/DataDownload_${periodfile}_daily_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/DataUpload_${periodfile}_daily_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/DataUsage_${periodfile}_daily_${IFACE_NAME}.htm" 2> /dev/null
				#cat "$CSV_OUTPUT_DIR/DataDownload_${periodfile}_weekly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/DataUpload_${periodfile}_weekly_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/DataUsage_${periodfile}_weekly_${IFACE_NAME}.htm" 2> /dev/null
				#cat "$CSV_OUTPUT_DIR/DataDownload_${periodfile}_monthly_${IFACE_NAME}.tmp" "$CSV_OUTPUT_DIR/DataUpload_${periodfile}_monthly_${IFACE_NAME}.tmp" > "$CSV_OUTPUT_DIR/DataUsage_${periodfile}_monthly_${IFACE_NAME}.htm" 2> /dev/null
			done

			csvlist="Combined Quality" # DataUsage"
			for csvfile in $csvlist
			do
				rm -f "$CSV_OUTPUT_DIR/${csvfile}daily_${IFACE_NAME}.htm"
				rm -f "$CSV_OUTPUT_DIR/${csvfile}weekly_${IFACE_NAME}.htm"
				rm -f "$CSV_OUTPUT_DIR/${csvfile}monthly_${IFACE_NAME}.htm"
				for periodfile in $periodfilelist
				do
					sed -i '1i Metric,Time,Value' "$CSV_OUTPUT_DIR/${csvfile}_${periodfile}_daily_${IFACE_NAME}.htm"
					sed -i '1i Metric,Time,Value' "$CSV_OUTPUT_DIR/${csvfile}_${periodfile}_weekly_${IFACE_NAME}.htm"
					sed -i '1i Metric,Time,Value' "$CSV_OUTPUT_DIR/${csvfile}_${periodfile}_monthly_${IFACE_NAME}.htm"
				done
			done

			INCLUDEURL=""
			if [ "$STORERESULTURL" = "true" ]; then
				INCLUDEURL=",[ResultURL]"
			fi

			{
			   echo ".mode csv"
			   echo ".headers on"
			   echo ".output $CSV_OUTPUT_DIR/CompleteResults_${IFACE_NAME}.htm"
			   echo "PRAGMA temp_store=1;"
			   echo "SELECT [Timestamp],[Download],[Upload],[Latency],[Jitter],[PktLoss]$INCLUDEURL,[DataDownload],[DataUpload],[ServerID],[ServerName] FROM spdstats_$IFACE_NAME WHERE ([Timestamp] >= strftime('%s',datetime($timenow,'unixepoch','-$(DaysToKeep check) day'))) ORDER BY [Timestamp] DESC;"
			} > /tmp/spd-complete.sql
			_ApplyDatabaseSQLCmds_ /tmp/spd-complete.sql "gnr10$gnrIndx1"

			rm -f /tmp/spd-complete.sql
			rm -f "$CSV_OUTPUT_DIR/Download"*
			rm -f "$CSV_OUTPUT_DIR/Upload"*
			rm -f "$CSV_OUTPUT_DIR/Latency"*
			rm -f "$CSV_OUTPUT_DIR/Jitter"*
			rm -f "$CSV_OUTPUT_DIR/PktLoss"*
			rm -f "$CSV_OUTPUT_DIR/DataDownload"*
			rm -f "$CSV_OUTPUT_DIR/DataUpload"*

			Generate_LastXResults "$IFACE_NAME" "$gnrIndx1"
			rm -f /tmp/spdTest-stats.sql
		done

		dos2unix "$CSV_OUTPUT_DIR/"*.htm

		tmpoutputdir="/tmp/${SCRIPT_NAME_LOWER}results"
		mkdir -p "$tmpoutputdir"
		mv -f "$CSV_OUTPUT_DIR/CompleteResults"*.htm "$tmpoutputdir/."

		if [ "$OUTPUTTIMEMODE" = "unix" ]
		then
			find "$tmpoutputdir/" -name '*.htm' -exec sh -c 'i="$1"; mv -- "$i" "${i%.htm}.csv"' _ {} \;
		elif [ "$OUTPUTTIMEMODE" = "non-unix" ]
		then
			for i in "$tmpoutputdir/"*".htm"; do
				awk -F"," 'NR==1 {OFS=","; print} NR>1 {OFS=","; $1=strftime("%Y-%m-%d %H:%M:%S", $1); print }' "$i" > "$i.out"
			done

			find "$tmpoutputdir/" -name '*.htm.out' -exec sh -c 'i="$1"; mv -- "$i" "${i%.htm.out}.csv"' _ {} \;
			rm -f "$tmpoutputdir/"*.htm
		fi

		if [ ! -f /opt/bin/7za ] && [ -x /opt/bin/opkg ]
		then
			opkg update
			opkg install p7zip
		fi
		/opt/bin/7za a -y -bsp0 -bso0 -tzip "/tmp/${SCRIPT_NAME_LOWER}data.zip" "$tmpoutputdir/*"
		mv -f "/tmp/${SCRIPT_NAME_LOWER}data.zip" "$CSV_OUTPUT_DIR"
		rm -rf "$tmpoutputdir"
	fi
	renice 0 $$
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Reset_DB()
{
	SIZEAVAIL="$(df -kP "$SCRIPT_STORAGE_DIR" | awk -F ' ' '{print $4}' | tail -n 1)"
	SIZEDB="$(ls -l "$SPEEDSTATS_DB" | awk -F ' ' '{print $5}')"
	SIZEAVAIL="$(echo "$SIZEAVAIL" | awk '{printf("%s", $1 * 1024);}')"

	if [ "$(echo "$SIZEAVAIL $SIZEDB" | awk -F ' ' '{print ($1 < $2)}')" -eq 1 ]
	then
		Print_Output true "Database size exceeds available space. $(ls -lh "$SPEEDSTATS_DB" | awk '{print $5}')B is required to create backup." "$ERR"
		return 1
	else
		Print_Output true "Sufficient free space to back up database, proceeding..." "$PASS"
		if ! cp -a "$SPEEDSTATS_DB" "${SPEEDSTATS_DB}.bak"; then
			Print_Output true "Database backup failed, please check storage device" "$WARN"
		fi

		Print_Output false "Please wait..." "$PASS"

		local rstIndx=0
		for dbtable in $FULL_IFACELIST
		do
			{
			   echo "PRAGMA temp_store=1;"
			   echo "DELETE FROM [spdstats_$dbtable];"
			} > /tmp/spdTest-reset.sql
			rstIndx="$((rstIndx + 1))"
			_ApplyDatabaseSQLCmds_ /tmp/spdTest-reset.sql "rst${rstIndx}"
			rm -f /tmp/spdTest-reset.sql
		done

		## Clear/Reset all CSV files ##
		Generate_CSVs

		## Show "reset" messages on webGUI ##
		timeDateNow="$(/bin/date +"%c")"
		extraJScode='databaseResetDone += 1;'
		echo "Resetting stats: $timeDateNow" > /tmp/spdstatstitle.txt
		WriteStats_ToJS /tmp/spdstatstitle.txt "$SCRIPT_STORAGE_DIR/spdtitletext.js" SetSPDStatsTitle statstitle "$extraJScode"
		rm -f /tmp/spdstatstitle.txt
		sleep 2
		Print_Output true "Database reset complete" "$WARN"
		{
		   sleep 4
		   _UpdateDatabaseFileSizeInfo_
		   timeDateNow="$(/bin/date +"%c")"
		   extraJScode='databaseResetDone = 0;'
		   echo "Stats were reset: $timeDateNow" > /tmp/spdstatstitle.txt
		   WriteStats_ToJS /tmp/spdstatstitle.txt "$SCRIPT_STORAGE_DIR/spdtitletext.js" SetSPDStatsTitle statstitle "$extraJScode"
		   rm -f /tmp/spdstatstitle.txt
		} &
	fi
}

Shortcut_Script()
{
	case $1 in
		create)
			if [ -d /opt/bin ] && [ ! -f "/opt/bin/$SCRIPT_NAME_LOWER" ] && \
			   [ -f "/jffs/scripts/$SCRIPT_NAME_LOWER" ]
			then
				ln -s "/jffs/scripts/$SCRIPT_NAME_LOWER" /opt/bin
				chmod 0755 "/opt/bin/$SCRIPT_NAME_LOWER"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME_LOWER" ]; then
				rm -f "/opt/bin/$SCRIPT_NAME_LOWER"
			fi
		;;
	esac
}

PressEnter()
{
	while true
	do
		printf "Press <Enter> key to continue..."
		read -rs key
		case "$key" in
			*) break ;;
		esac
	done
	return 0
}

ScriptHeader()
{
	clear
	printf "\\n"
	printf "${BOLD}################################################################${CLEARFORMAT}\\n"
	printf "${BOLD}##                     _  __  __              _  _            ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                    | ||  \/  |            | |(_)           ##${CLEARFORMAT}\\n"
	printf "${BOLD}##     ___  _ __    __| || \  / |  ___  _ __ | | _  _ __      ##${CLEARFORMAT}\\n"
	printf "${BOLD}##    / __|| '_ \  / _  || |\/| | / _ \| '__|| || || '_ \     ##${CLEARFORMAT}\\n"
	printf "${BOLD}##    \__ \| |_) || (_| || |  | ||  __/| |   | || || | | |    ##${CLEARFORMAT}\\n"
	printf "${BOLD}##    |___/| .__/  \__,_||_|  |_| \___||_|   |_||_||_| |_|    ##${CLEARFORMAT}\\n"
	printf "${BOLD}##        | |                                                 ##${CLEARFORMAT}\\n"
	printf "${BOLD}##        |_|                                                 ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                                                            ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                  %9s on %-18s           ##${CLEARFORMAT}\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "${BOLD}##                                                            ##${CLEARFORMAT}\\n"
	printf "${BOLD}##            https://github.com/AMTM-OSR/spdMerlin           ##${CLEARFORMAT}\\n"
	printf "${BOLD}##      Forked from https://github.com/jackyaz/spdMerlin      ##${CLEARFORMAT}\\n"
	printf "${BOLD}##                                                            ##${CLEARFORMAT}\\n"
	printf "${BOLD}################################################################${CLEARFORMAT}\\n"
	printf "\\n"
}

##-------------------------------------##
## Added by Martinski W. [2025-Jan-19] ##
##-------------------------------------##
_CronScheduleHourMinsInfo_()
{
   if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]
   then echo ; return 1 ; fi
   local schedHour="$1"  schedMins="$2"  schedInfoStr
   local freqHourNum  freqMinsNum  hasFreqHour  hasFreqMins

   _IsValidNumber_()
   {
      if echo "$1" | grep -qE "^[0-9]+$"
      then return 0 ; else return 1 ; fi
   }

   _Get12HourAmPm_()
   {
      if [ $# -eq 0 ] || [ -z "$1" ]
      then echo ; return 1 ; fi
      local theHour  theMins=""  ampmTag="AM"
      theHour="$1"
      if [ $# -eq 2 ] && [ -n "$2" ]
      then theMins="$2"
      fi
      if [ "$theHour" -eq 0 ]
      then theHour=12
      elif [ "$theHour" -eq 12 ]
      then ampmTag="PM"
      elif [ "$theHour" -gt 12 ]
      then
          ampmTag="PM" ; theHour="$((theHour - 12))"
      fi
      if [ -z "$theMins" ]
      then printf "%d $ampmTag" "$theHour"
      else printf "%d:%02d $ampmTag" "$theHour" "$theMins"
      fi
   }

   if echo "$schedHour" | grep -qE "^[*]/.*"
   then
       hasFreqHour=true
       freqHourNum="$(echo "$schedHour" | cut -f2 -d'/')"
   else
       hasFreqHour=false ; freqHourNum=""
   fi
   if echo "$schedMins" | grep -qE "^[*]/.*"
   then
       hasFreqMins=true
       freqMinsNum="$(echo "$schedMins" | cut -f2 -d'/')"
   else
       hasFreqMins=false ; freqMinsNum=""
   fi
   if [ "$schedHour" = "*" ] && [ "$schedMins" = "0" ]
   then
       schedInfoStr="Every hour"
   elif [ "$schedHour" = "*" ] && [ "$schedMins" = "*" ]
   then
       schedInfoStr="Every minute"
   elif [ "$schedHour" = "*" ] && _IsValidNumber_ "$schedMins"
   then
       schedInfoStr="Every hour at minute $schedMins"
   elif "$hasFreqHour" && [ "$schedMins" = "0" ]
   then
       schedInfoStr="Every $freqHourNum hours"
   elif "$hasFreqHour" && [ "$schedMins" = "*" ]
   then
       schedInfoStr="Every minute, every $freqHourNum hours"
   elif "$hasFreqHour" && _IsValidNumber_ "$schedMins"
   then
       schedInfoStr="Every $freqHourNum hours at minute $schedMins"
   elif "$hasFreqMins" && [ "$schedHour" = "*" ]
   then
       schedInfoStr="Every $freqMinsNum minutes"
   elif "$hasFreqHour" && "$hasFreqMins"
   then
       schedInfoStr="Every $freqMinsNum minutes, every $freqHourNum hours"
   elif "$hasFreqMins" && _IsValidNumber_ "$schedHour"
   then
       schedInfoStr="Hour: $(_Get12HourAmPm_ "$schedHour"), every $freqMinsNum minutes"
   elif _IsValidNumber_ "$schedHour" && _IsValidNumber_ "$schedMins"
   then
       schedInfoStr="Hour: $(_Get12HourAmPm_ "$schedHour" "$schedMins")"
   elif "$hasFreqHour"
   then
       schedInfoStr="Every $freqHourNum hours, Minutes: $schedMins"
   elif "$hasFreqMins"
   then
       schedInfoStr="Hours: ${schedHour}; every $freqMinsNum minutes"
   elif [ "$schedHour" = "*" ]
   then
       schedInfoStr="Every hour, Minutes: $schedMins"
   elif [ "$schedMins" = "*" ]
   then
       schedInfoStr="Hours: ${schedHour}; every minute"
   else
       schedInfoStr="Hours: ${schedHour}; Minutes: $schedMins"
   fi
   echo "$schedInfoStr"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
MainMenu()
{
	local menuOption  storageLocStr  automaticModeStatus
	local jffsFreeSpace  jffsFreeSpaceStr  jffsSpaceMsgTag

	if [ "$(ExcludeFromQoS check)" = "true" ]
	then EXCLUDEFROMQOS_MENU="excluded from"
    else EXCLUDEFROMQOS_MENU="included in"
    fi

	if AutomaticMode check
	then automaticModeStatus="${PassBGRNct} ENABLED ${CLRct}"
	else automaticModeStatus="${CritIREDct} DISABLED ${CLRct}"
	fi

	TEST_SCHEDULE="$(CronTestSchedule check)"
    CRON_SCHED_DAYS="$(echo "$TEST_SCHEDULE" | cut -f1 -d'|')"
	CRON_SCHED_HOUR="$(echo "$TEST_SCHEDULE" | cut -f2 -d'|')"
	CRON_SCHED_MINS="$(echo "$TEST_SCHEDULE" | cut -f3 -d'|')"
	if [ "$CRON_SCHED_DAYS" = "*" ]
	then TEST_SCHEDULE_DAYS="Every day"
	else TEST_SCHEDULE_DAYS="Days of Week: $CRON_SCHED_DAYS"
	fi
	TEST_SCHEDULE_MENU="$(_CronScheduleHourMinsInfo_ "$CRON_SCHED_HOUR" "$CRON_SCHED_MINS")"

	if [ "$(StoreResultURL check)" = "true" ]
	then STORERESULTURL_MENU="ENABLED"
	else STORERESULTURL_MENU="DISABLED"
	fi

	storageLocStr="$(ScriptStorageLocation check | tr 'a-z' 'A-Z')"

	jffsFreeSpace="$(_Get_JFFS_Space_ FREE HRx | sed 's/%/%%/')"
	if ! echo "$JFFS_LowFreeSpaceStatus" | grep -E "^WARNING[0-9]$"
	then
		jffsFreeSpaceStr="${SETTING}$jffsFreeSpace"
	else
		if [ "$storageLocStr" = "JFFS" ]
		then jffsSpaceMsgTag="${CritBREDct} <<< WARNING! "
		else jffsSpaceMsgTag="${WarnBMGNct} <<< NOTICE! "
		fi
		jffsFreeSpaceStr="${WarnBYLWct} $jffsFreeSpace ${CLRct}  ${jffsSpaceMsgTag}${CLRct}"
	fi

	printf "WebUI for %s is available at:\n${SETTING}%s${CLEARFORMAT}\n\n" "$SCRIPT_NAME" "$(Get_WebUI_URL)"

	printf "1.    Run a speedtest now\n"
	printf "      Database size: ${SETTING}%s${CLEARFORMAT}\n\n" "$(_GetFileSize_ "$SPEEDSTATS_DB" HRx)"
	printf "2.    Choose a preferred server for an interface\n\n"
	printf "3.    Toggle automatic speedtests\n"
	printf "      Currently: ${automaticModeStatus}${CLEARFORMAT}\n\n"
	printf "4.    Configure schedule for automatic speedtests\n"
	printf "      Currently: ${SETTING}%s - %s${CLEARFORMAT}\n\n" "$TEST_SCHEDULE_MENU" "$TEST_SCHEDULE_DAYS"
	printf "5.    Toggle time output mode\n"
	printf "      Currently: ${SETTING}%s${CLEARFORMAT} time values will be used for CSV exports\n\n" "$(OutputTimeMode check)"
	printf "6.    Toggle storage of speedtest result URLs\n"
	printf "      Currently: ${SETTING}%s${CLEARFORMAT}\n\n" "$STORERESULTURL_MENU"
	printf "7.    Set number of speedtest results to show in WebUI\n"
	printf "      Currently: ${SETTING}%s results will be shown${CLEARFORMAT}\n\n" "$(LastXResults check)"
	printf "8.    Set number of days data to keep in database\n"
	printf "      Currently: ${SETTING}%s days data will be kept${CLEARFORMAT}\n\n" "$(DaysToKeep check)"
	printf "9.    Toggle between built-in Ookla speedtest and speedtest-cli\n"
	printf "      Currently: ${SETTING}%s${CLEARFORMAT} binary will be used for speedtests${CLEARFORMAT}\n\n" "$(SpeedtestBinary check)"
	printf "c.    Customise list of interfaces for automatic speedtests\n"
	printf "r.    Reset list of interfaces for automatic speedtests to default\n\n"
	printf "s.    Toggle storage location for stats and config\n"
	printf "      Current location: ${SETTING}%s${CLEARFORMAT}\n" "$storageLocStr"
    printf "      JFFS Available: ${jffsFreeSpaceStr}${CLEARFORMAT}\n\n"
	printf "q.    Toggle exclusion of %s speedtests from QoS\n" "$SCRIPT_NAME"
	printf "      Currently: %s speedtests are ${SETTING}%s${CLEARFORMAT} QoS\n\n" "$SCRIPT_NAME" "$EXCLUDEFROMQOS_MENU"
	printf "a.    AutoBW\n\n"
	printf "u.    Check for updates\n"
	printf "uf.   Update %s with latest version (force update)\n\n" "$SCRIPT_NAME"
	printf "rs.   Reset %s database / delete all data\n\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\n\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\n" "$SCRIPT_NAME"
	printf "\n"
	printf "${BOLD}####################################################################${CLEARFORMAT}\n"
	printf "\n"
	
	while true
	do
		printf "Choose an option:  "
		read -r menuOption
		case "$menuOption" in
			1)
				printf "\n"
				Menu_RunSpeedtest && PressEnter
				break
			;;
			2)
				printf "\n"
				Menu_ConfigurePreferred && PressEnter
				break
			;;
			3)
				printf "\n"
				if AutomaticMode check
				then AutomaticMode disable
				else AutomaticMode enable
				fi
				PressEnter
				break
			;;
			4)
				printf "\n"
				Menu_EditSchedule
				PressEnter
				break
			;;
			5)
				printf "\n"
				if [ "$(OutputTimeMode check)" = "unix" ]; then
					OutputTimeMode non-unix
				elif [ "$(OutputTimeMode check)" = "non-unix" ]; then
					OutputTimeMode unix
				fi
				break
			;;
			6)
				printf "\n"
				if [ "$(StoreResultURL check)" = "true" ]; then
					StoreResultURL disable
				elif [ "$(StoreResultURL check)" = "false" ]; then
					StoreResultURL enable
				fi
				break
			;;
			7)
				printf "\n"
				LastXResults update && PressEnter
				break
			;;
			8)
				printf "\n"
				DaysToKeep update && PressEnter
				break
			;;
			9)
				printf "\n"
				if [ "$(SpeedtestBinary check)" = "builtin" ]; then
					SpeedtestBinary external
				elif [ "$(SpeedtestBinary check)" = "external" ]; then
					SpeedtestBinary builtin
				fi
				break
			;;
			c)
				Generate_Interface_List
				printf "\n"
				Create_Symlinks
				printf "\n"
				break
			;;
			r)
				Create_Symlinks force
				printf "\n"
				PressEnter
				break
			;;
			s)
				printf "\n"
				if Check_Lock menu
				then
					if [ "$(ScriptStorageLocation check)" = "jffs" ]
					then
					    ScriptStorageLocation usb
					elif [ "$(ScriptStorageLocation check)" = "usb" ]
					then
					    if ! _Check_JFFS_SpaceAvailable_ "$SCRIPT_STORAGE_DIR"
					    then
					        Clear_Lock
					        PressEnter
					        break
					    fi
					    ScriptStorageLocation jffs
					fi
					Create_Symlinks
					Clear_Lock
				fi
				break
			;;
			q)
				printf "\n"
				if [ "$(ExcludeFromQoS check)" = "true" ]
				then
					if [ "$(AutoBWEnable check)" = "true" ]
					then
						Print_Output false "Cannot disable Exclude from QoS when AutoBW is enabled" "$WARN"
						PressEnter
					elif [ "$(AutoBWEnable check)" = "false" ]
					then
						ExcludeFromQoS disable
					fi
				elif [ "$(ExcludeFromQoS check)" = "false" ]
				then
					ExcludeFromQoS enable
				fi
				break
			;;
			a)
				printf "\\n"
				Menu_AutoBW
				break
			;;
			u)
				printf "\n"
				if Check_Lock menu; then
					Update_Version
					Clear_Lock
				fi
				PressEnter
				break
			;;
			uf)
				printf "\n"
				if Check_Lock menu; then
					Update_Version force
					Clear_Lock
				fi
				PressEnter
				break
			;;
			rs)
				printf "\n"
				if Check_Lock menu; then
					Menu_ResetDB
					Clear_Lock
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\n${BOLD}Thanks for using %s!${CLEARFORMAT}\n\n\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true
				do
					printf "\n${BOLD}Are you sure you want to uninstall %s? (y/n)${CLEARFORMAT}  " "$SCRIPT_NAME"
					read -r confirm
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
			;;
			*)
				[ -n "$menuOption" ] && \
				printf "\n${REDct}INVALID input [$menuOption]${CLEARFORMAT}"
				printf "\nPlease choose a valid option.\n\n"
				PressEnter
				break
			;;
		esac
	done

	ScriptHeader
	MainMenu
}

Check_Requirements()
{
	CHECKSFAILED="false"

	if [ "$(nvram get jffs2_scripts)" -ne 1 ]
	then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output true "Custom JFFS Scripts enabled" "$WARN"
	fi

	if ! Check_Swap
	then
		Print_Output false "No Swap file detected!" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ ! -f /opt/bin/opkg ]
	then
		Print_Output false "Entware NOT detected!" "$CRIT"
		CHECKSFAILED="true"
	fi

	if ! Firmware_Version_Check
	then
		Print_Output false "Unsupported firmware version detected" "$CRIT"
		Print_Output false "$SCRIPT_NAME requires Merlin 384.15/384.13_4 or Fork 43E5 (or later)" "$ERR"
		CHECKSFAILED="true"
	fi

	if [ "$CHECKSFAILED" = "false" ]
	then
		Print_Output false "Installing required packages from Entware" "$PASS"
		opkg update
		opkg install sqlite3-cli
		opkg install jq
		opkg install p7zip
		opkg install findutils
		return 0
	else
		return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
Menu_Install()
{
	ScriptHeader
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz" "$PASS"
	sleep 1

	Print_Output true "By installing $SCRIPT_NAME you are agreeing to Ookla's license: $SCRIPT_REPO/speedtest-cli-license" "$WARN"

	printf "\n${BOLD}Do you wish to continue? (y/n)${CLEARFORMAT}  " "$SCRIPT_NAME"
	read -r confirm
	case "$confirm" in
		y|Y)
			:
		;;
		*)
			Print_Output true "You did not agree to Ookla's license, removing $SCRIPT_NAME" "$CRIT"
			Clear_Lock
			rm -f "/jffs/scripts/$SCRIPT_NAME_LOWER" 2>/dev/null
			exit 1
		;;
	esac

	Print_Output true "Checking if your router meets the requirements for $SCRIPT_NAME" "$PASS"

	if ! Check_Requirements
	then
		Print_Output true "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME_LOWER" 2>/dev/null
		exit 1
	fi

	Create_Dirs
	Conf_Exists
	if [ "$(SpeedtestBinary check)" = "builtin" ]; then
		printf "/usr/sbin/ookla" > /tmp/spdmerlin-binary
	elif [ "$(SpeedtestBinary check)" = "external" ]; then
		printf "%s" "$OOKLA_DIR/speedtest" > /tmp/spdmerlin-binary
	fi
	Set_Version_Custom_Settings local "$SCRIPT_VERSION"
	Set_Version_Custom_Settings server "$SCRIPT_VERSION"
	ScriptStorageLocation load
	Create_Symlinks

	Download_File "$SCRIPT_REPO/$ARCH.tar.gz" "$OOKLA_DIR/$ARCH.tar.gz"
	tar -xzf "$OOKLA_DIR/$ARCH.tar.gz" -C "$OOKLA_DIR"
	rm -f "$OOKLA_DIR/$ARCH.tar.gz"
	chmod 0755 "$OOKLA_DIR/speedtest"

	Update_File README.md
	Update_File spdstats_www.asp
	Update_File shared-jy.tar.gz

	Auto_Startup create 2>/dev/null
	Auto_Cron delete 2>/dev/null
	AutomaticMode check && Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create

	Process_Upgrade

	Run_Speedtest auto WAN

	Clear_Lock

	Download_File "$SCRIPT_REPO/LICENSE" "$SCRIPT_DIR/LICENSE"

	ScriptHeader
	MainMenu
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-04] ##
##----------------------------------------##
Menu_Startup()
{
	if [ $# -eq 0 ] || [ -z "$1" ]
	then
		Print_Output true "Missing argument for startup, not starting $SCRIPT_NAME" "$ERR"
		exit 1
	elif [ "$1" != "force" ]
	then
		if [ ! -x "${1}/entware/bin/opkg" ]
		then
			Print_Output true "$1 does NOT contain Entware, not starting $SCRIPT_NAME" "$CRIT"
			exit 1
		else
			Print_Output true "$1 contains Entware, starting $SCRIPT_NAME" "$PASS"
		fi
	fi

	NTP_Ready
	Check_Lock
	
	if [ "$1" != "force" ]; then
		sleep 8
	fi
	
	Create_Dirs
	Conf_Exists
	if [ "$(SpeedtestBinary check)" = "builtin" ]; then
		printf "/usr/sbin/ookla" > /tmp/spdmerlin-binary
	elif [ "$(SpeedtestBinary check)" = "external" ]; then
		printf "%s" "$OOKLA_DIR/speedtest" > /tmp/spdmerlin-binary
	fi
	ScriptStorageLocation load
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	if AutomaticMode check
	then Auto_Cron create 2>/dev/null
	else Auto_Cron delete 2>/dev/null
	fi
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	Mount_WebUI
	Clear_Lock
}

##----------------------------------------##
## Modified by Martinski W. [2025-Mar-03] ##
##----------------------------------------##
Menu_RunSpeedtest()
{
	exitmenu=""
	validselection=""
	useiface=""
	usepreferred=""
	ScriptHeader
	while true
	do
		printf "Choose an interface to speedtest:\n\n"
		printf "1.    All\n"
		COUNTER="2"
		while IFS='' read -r line || [ -n "$line" ]
		do
			if [ "$(echo "$line" | grep -c "interface not up")" -eq 0 ]
			then
				printf "%s.    %s\n" "$COUNTER" "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				COUNTER="$((COUNTER+1))"
			fi
		done < "$SCRIPT_INTERFACES_USER"
		printf "\nChoose an option (e=Exit):  "
		read -r iface_choice

		if [ "$iface_choice" = "e" ]
		then
			exitmenu="exit"
			break
		elif ! Validate_Number "$iface_choice"
		then
			printf "\n${ERR}Please enter a valid number [1-%s].${CLEARFORMAT}\n" "$((COUNTER-1))"
			validselection="false"
		else
			if [ "$iface_choice" -lt 1 ] || [ "$iface_choice" -gt "$((COUNTER-1))" ]
			then
				printf "\n${ERR}Please enter a number between 1 and %s.${CLEARFORMAT}\n" "$((COUNTER-1))"
				validselection="false"
			else
				if [ "$iface_choice" -gt "1" ]
				then
					useiface="$(grep -v "interface not up" "$SCRIPT_INTERFACES_USER" | sed -n $((iface_choice-1))p | cut -f1 -d"#" | sed 's/ *$//')"
				else
					useiface="All"
				fi
				validselection="true"
			fi
		fi
		printf "\n"

		if [ "$exitmenu" != "exit" ] && [ "$validselection" != "false" ]
		then
			while true
			do
				printf "What mode would you like to use?\n\n"
				printf "1.    Auto-select\n"
				printf "2.    Preferred server\n"
				printf "3.    Choose a server\n"
				printf "\nChoose an option (e=Exit):  "
				read -r usepref_choice

				if [ "$usepref_choice" = "e" ]
				then
					exitmenu="exit"
					break
				elif ! Validate_Number "$usepref_choice"
				then
					printf "\n${ERR}Please enter a valid number [1-3].${CLEARFORMAT}\n"
					validselection="false" ; echo
				else
					if [ "$usepref_choice" -lt 1 ] || [ "$usepref_choice" -gt 3 ]
					then
						printf "\n${ERR}Please enter a number between 1 and 3.${CLEARFORMAT}\n"
						validselection="false" ; echo
					else
						case "$usepref_choice" in
							1) usepreferred="auto" ;;
							2) usepreferred="user" ;;
							3) usepreferred="onetime" ;;
						esac
						validselection="true" ; echo
						break
					fi
				fi
			done
		fi
		if [ "$exitmenu" != "exit" ] && [ "$validselection" != "false" ]
		then
			if Check_Lock menu; then
				Run_Speedtest "$usepreferred" "$useiface"
				Clear_Lock
			fi
		elif [ "$exitmenu" = "exit" ]; then
			break
		fi
		printf "\n"
		PressEnter
		ScriptHeader
	done

	if [ "$exitmenu" != "exit" ]
    then return 0
	else echo ; return 1
	fi
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-29] ##
##----------------------------------------##
Menu_ConfigurePreferred()
{
	exitmenu=""
	prefiface=""
	ScriptHeader
	while true
	do
		printf "Choose an interface to configure server preference for:\n\n"
		printf "1.    All (on/off only)\n\n"
		COUNTER="2"
		while IFS='' read -r line || [ -n "$line" ]
		do
			if [ "$(echo "$line" | grep -c "interface not up")" -eq 0 ]
			then
				pref_enabled=""
				if PreferredServer check "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				then pref_enabled="On"; else pref_enabled="Off"; fi
				printf "%s.    %s\n" "$COUNTER" "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
				printf "      Preferred: %s - Server: %s\n\n" "$pref_enabled" "$(PreferredServer list "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')" | cut -f2 -d'|')"
				COUNTER=$((COUNTER+1))
			fi
		done < "$SCRIPT_INTERFACES_USER"

		while true
		do
			printf "\nChoose an option (e=Exit):  "
			read -r iface_choice

			if [ "$iface_choice" = "e" ]
			then
				exitmenu="exit"
				break
			elif ! Validate_Number "$iface_choice"
			then
				printf "\n${ERR}Please enter a valid number [1-%s].${CLEARFORMAT}\n" "$((COUNTER-1))"
			else
				if [ "$iface_choice" -lt 1 ] || [ "$iface_choice" -gt "$((COUNTER-1))" ]
				then
					printf "\n${ERR}Please enter a number between 1 and %s.${CLEARFORMAT}\n" "$((COUNTER-1))"
				else
					if [ "$iface_choice" -gt "1" ]
					then
						prefiface="$(grep -v "interface not up" "$SCRIPT_INTERFACES_USER" | sed -n $((iface_choice-1))p | cut -f1 -d"#" | sed 's/ *$//')"
						break
					else
						prefiface="All"
						break
					fi
				fi
			fi
		done

		printf "\n"

		if [ "$exitmenu" != "exit" ]
		then
			if [ "$prefiface" = "All" ]
			then
				while true
				do
					printf "What would you like to do?\n\n"
					printf "1.    Turn on preferred servers\n"
					printf "2.    Turn off preferred servers\n"
					printf "\nChoose an option (e=Exit):  "
					read -r usepref_choice

					if [ "$usepref_choice" = "e" ]
					then
						break
					elif ! Validate_Number "$usepref_choice"
					then
						printf "\n${ERR}Please enter a valid number [1-2].${CLEARFORMAT}\n"
					else
						if [ "$usepref_choice" -lt 1 ] || [ "$usepref_choice" -gt 2 ]
						then
							printf "\n${ERR}Please enter a number between 1 and 2.${CLEARFORMAT}\n\n"
						else
							prefenabledisable=""
							if [ "$usepref_choice" -eq 1 ]
							then
								prefenabledisable="enable"
							else
								prefenabledisable="disable"
							fi
							while IFS='' read -r line || [ -n "$line" ]
							do
								if [ "$(echo "$line" | grep -c "interface not up")" -eq 0 ]
								then
									PreferredServer "$prefenabledisable" "$(echo "$line" | cut -f1 -d"#" | sed 's/ *$//')"
								fi
							done < "$SCRIPT_INTERFACES_USER"
							printf "\n"
							break
						fi
					fi
				done
			else
				while true
				do
					pref_enabled=""
					if PreferredServer check "$prefiface"
					then pref_enabled="On"; else pref_enabled="Off"
					fi
					printf "What would you like to do?\n\n"
					printf "1.    Toggle preferred server on/off - currently: %s\n" "$pref_enabled"
					printf "2.    Set preferred server - currently: %s\n" "$(PreferredServer list "$prefiface" | cut -f2 -d"|")"
					printf "\nChoose an option (e=Exit):  "
					read -r ifpref_choice

					if [ "$ifpref_choice" = "e" ]
					then
						break
					elif ! Validate_Number "$ifpref_choice"
					then
						printf "\n${ERR}Please enter a valid number [1-2].${CLEARFORMAT}\n"
					else
						if [ "$ifpref_choice" -lt 1 ] || [ "$ifpref_choice" -gt 2 ]
						then
							printf "\n${ERR}Please enter a number between 1 and 2.${CLEARFORMAT}\n"
						else
							if [ "$ifpref_choice" -eq 1 ]
							then
								printf "\n"
								if PreferredServer check "$prefiface"
								then
									PreferredServer disable "$prefiface"
								else
									PreferredServer enable "$prefiface"
								fi
								break
							elif [ "$ifpref_choice" -eq 2 ]
							then
								printf "\n"
								PreferredServer "update" "$prefiface"
								break
							fi
						fi
					fi
				done
			fi
		fi
		if [ "$exitmenu" = "exit" ]; then
			break
		fi
		printf "\n"
		PressEnter
		ScriptHeader
	done

	if [ "$exitmenu" != "exit" ]
	then
		return 0
	else
		echo ; return 1
	fi
}

Menu_EditSchedule()
{
	exitmenu=""
	formattype=""
	crudays=""
	crudaysvalidated=""
	cruhours=""
	crumins=""
	
	while true
	do
		printf "\n${BOLD}Please choose which day(s) to run speedtest (0-6 - 0 = Sunday, * for every day, or comma separated days):${CLEARFORMAT}  "
		read -r day_choice
		
		if [ "$day_choice" = "e" ]
		then
			exitmenu="exit"
			break
		elif [ "$day_choice" = "*" ]
		then
			crudays="$day_choice"
			printf "\n"
			break
		elif [ -z "$day_choice" ]
		then
			printf "\n${ERR}Please enter a valid number (0-6) or comma separated values${CLEARFORMAT}\n"
		else
			crudaystmp="$(echo "$day_choice" | sed "s/,/ /g")"
			crudaysvalidated="true"
			for i in $crudaystmp
			do
				if echo "$i" | grep -q "-"
				then
					if [ "$i" = "-" ]
					then
						printf "\n${ERR}Please enter a valid number (0-6)${CLEARFORMAT}\n"
						crudaysvalidated="false"
						break
					fi
					crudaystmp2="$(echo "$i" | sed "s/-/ /")"
					for i2 in $crudaystmp2
					do
						if ! Validate_Number "$i2"
						then
							printf "\n${ERR}Please enter a valid number (0-6)${CLEARFORMAT}\n"
							crudaysvalidated="false"
							break
						elif [ "$i2" -lt 0 ] || [ "$i2" -gt 6 ]
						then
							printf "\n${ERR}Please enter a number between 0 and 6${CLEARFORMAT}\n"
							crudaysvalidated="false"
							break
						fi
					done
				elif ! Validate_Number "$i"
				then
					printf "\n${ERR}Please enter a valid number (0-6) or comma separated values${CLEARFORMAT}\n"
					crudaysvalidated="false"
					break
				else
					if [ "$i" -lt 0 ] || [ "$i" -gt 6 ]
					then
						printf "\n${ERR}Please enter a number between 0 and 6 or comma separated values${CLEARFORMAT}\n"
						crudaysvalidated="false"
						break
					fi
				fi
			done
			if [ "$crudaysvalidated" = "true" ]
			then
				crudays="$day_choice"
				printf "\n"
				break
			fi
		fi
	done
	
	if [ "$exitmenu" != "exit" ]
	then
		while true
		do
			printf "\n${BOLD}Please choose the format to specify the hour/minute(s) to run speedtest:${CLEARFORMAT}\n"
			printf "    1. Every X hours/minutes\n"
			printf "    2. Custom\n\n"
			printf "Choose an option:  "
			read -r formatmenu
			
			case "$formatmenu" in
				1)
					formattype="everyx"
					printf "\n"
					break
				;;
				2)
					formattype="custom"
					printf "\n"
					break
				;;
				e)
					exitmenu="exit"
					break
				;;
				*)
					printf "\n${ERR}Please enter a valid choice (1-2)${CLEARFORMAT}\n"
				;;
			esac
		done
	fi
	
	if [ "$exitmenu" != "exit" ]
	then
		if [ "$formattype" = "everyx" ]
		then
			while true
			do
				printf "\n${BOLD}Please choose whether to specify every X hours or every X minutes to run speedtest:${CLEARFORMAT}\n"
				printf "    1. Hours\n"
				printf "    2. Minutes\n\n"
				printf "Choose an option:  "
				read -r formatmenu
				
				case "$formatmenu" in
					1)
						formattype="hours"
						printf "\\n"
						break
					;;
					2)
						formattype="mins"
						printf "\\n"
						break
					;;
					e)
						exitmenu="exit"
						break
					;;
					*)
						printf "\n${ERR}Please enter a valid choice (1-2)${CLEARFORMAT}\n"
					;;
				esac
			done
		fi
	fi
	
	if [ "$exitmenu" != "exit" ]
	then
		if [ "$formattype" = "hours" ]
		then
			while true
			do
				printf "\\n${BOLD}Please choose how often to run speedtest (every X hours, where X is 1-24):${CLEARFORMAT}  "
				read -r hour_choice
				
				if [ "$hour_choice" = "e" ]
				then
					exitmenu="exit"
					break
				elif ! Validate_Number "$hour_choice"
				then
						printf "\\n${ERR}Please enter a valid number (1-24)${CLEARFORMAT}\\n"
				elif [ "$hour_choice" -lt 1 ] || [ "$hour_choice" -gt 24 ]
				then
					printf "\\n${ERR}Please enter a number between 1 and 24${CLEARFORMAT}\\n"
				elif [ "$hour_choice" -eq 24 ]
				then
					cruhours=0
					crumins=0
					printf "\\n"
					break
				else
					cruhours="*/$hour_choice"
					crumins=0
					printf "\\n"
					break
				fi
			done
		elif [ "$formattype" = "mins" ]
		then
			while true
			do
				printf "\\n${BOLD}Please choose how often to run speedtest (every X minutes, where X is 1-30):${CLEARFORMAT}  "
				read -r min_choice
				
				if [ "$min_choice" = "e" ]
				then
					exitmenu="exit"
					break
				elif ! Validate_Number "$min_choice"
				then
						printf "\\n${ERR}Please enter a valid number (1-30)${CLEARFORMAT}\\n"
				elif [ "$min_choice" -lt 1 ] || [ "$min_choice" -gt 30 ]
				then
					printf "\\n${ERR}Please enter a number between 1 and 30${CLEARFORMAT}\\n"
				else
					crumins="*/$min_choice"
					cruhours="*"
					printf "\\n"
					break
				fi
			done
		fi
	fi
	
	if [ "$exitmenu" != "exit" ]
	then
		if [ "$formattype" = "custom" ]
		then
			while true
			do
				printf "\\n${BOLD}Please choose which hour(s) to run speedtest (0-23, * for every hour, or comma separated hours):${CLEARFORMAT}  "
				read -r hour_choice
				
				if [ "$hour_choice" = "e" ]
				then
					exitmenu="exit"
					break
				elif [ "$hour_choice" = "*" ]
				then
					cruhours="$hour_choice"
					printf "\\n"
					break
				else
					cruhourstmp="$(echo "$hour_choice" | sed "s/,/ /g")"
					cruhoursvalidated="true"
					for i in $cruhourstmp
					do
						if echo "$i" | grep -q "-"
						then
							if [ "$i" = "-" ]
							then
								printf "\\n${ERR}Please enter a valid number (0-23)${CLEARFORMAT}\\n"
								cruhoursvalidated="false"
								break
							fi
							cruhourstmp2="$(echo "$i" | sed "s/-/ /")"
							for i2 in $cruhourstmp2
							do
								if ! Validate_Number "$i2"
								then
									printf "\\n${ERR}Please enter a valid number (0-23)${CLEARFORMAT}\\n"
									cruhoursvalidated="false"
									break
								elif [ "$i2" -lt 0 ] || [ "$i2" -gt 23 ]
								then
									printf "\\n${ERR}Please enter a number between 0 and 23${CLEARFORMAT}\\n"
									cruhoursvalidated="false"
									break
								fi
							done
						elif echo "$i" | grep -q "/"
						then
							cruhourstmp3="$(echo "$i" | sed "s/\*\///")"
							if ! Validate_Number "$cruhourstmp3"
							then
								printf "\\n${ERR}Please enter a valid number (0-23)${CLEARFORMAT}\\n"
								cruhoursvalidated="false"
								break
							elif [ "$cruhourstmp3" -lt 0 ] || [ "$cruhourstmp3" -gt 23 ]
							then
								printf "\\n${ERR}Please enter a number between 0 and 23${CLEARFORMAT}\\n"
								cruhoursvalidated="false"
								break
							fi
						elif ! Validate_Number "$i"
						then
							printf "\\n${ERR}Please enter a valid number (0-23) or comma separated values${CLEARFORMAT}\\n"
							cruhoursvalidated="false"
							break
						elif [ "$i" -lt 0 ] || [ "$i" -gt 23 ]
						then
							printf "\\n${ERR}Please enter a number between 0 and 23 or comma separated values${CLEARFORMAT}\\n"
							cruhoursvalidated="false"
							break
						fi
					done
					if [ "$cruhoursvalidated" = "true" ]
					then
						if echo "$hour_choice" | grep -q "-"
						then
							cruhours1="$(echo "$hour_choice" | cut -f1 -d'-')"
							cruhours2="$(echo "$hour_choice" | cut -f2 -d'-')"
							if [ "$cruhours1" -lt "$cruhours2" ]
							then
								cruhours="$hour_choice"
							elif [ "$cruhours2" -lt "$cruhours1" ]
							then
								cruhours="$cruhours1-23,0-$cruhours2"
							fi
						else
							cruhours="$hour_choice"
						fi
						printf "\\n"
						break
					fi
				fi
			done
		fi
	fi
	
	if [ "$exitmenu" != "exit" ]
	then
		if [ "$formattype" = "custom" ]
		then
			while true
			do
				printf "\\n${BOLD}Please choose which minutes(s) to run speedtest (0-59, * for every minute, or comma separated minutes):${CLEARFORMAT}  "
				read -r min_choice
				
				if [ "$min_choice" = "e" ]
				then
					exitmenu="exit"
					break
				elif [ "$min_choice" = "*" ]
				then
					crumins="$min_choice"
					printf "\\n"
					break
				else
					cruminstmp="$(echo "$min_choice" | sed "s/,/ /g")"
					cruminsvalidated="true"
					for i in $cruminstmp
					do
						if echo "$i" | grep -q "-"
						then
							if [ "$i" = "-" ]
							then
								printf "\\n${ERR}Please enter a valid number (0-23)${CLEARFORMAT}\\n"
								cruminsvalidated="false"
								break
							fi
							cruminstmp2="$(echo "$i" | sed "s/-/ /")"
							for i2 in $cruminstmp2
							do
								if ! Validate_Number "$i2"
								then
									printf "\\n${ERR}Please enter a valid number (0-59)${CLEARFORMAT}\\n"
									cruminsvalidated="false"
									break
								elif [ "$i2" -lt 0 ] || [ "$i2" -gt 59 ]
								then
									printf "\\n${ERR}Please enter a number between 0 and 59${CLEARFORMAT}\\n"
									cruminsvalidated="false"
									break
								fi
							done
						elif echo "$i" | grep -q "/"
						then
							cruminstmp3="$(echo "$i" | sed "s/\*\///")"
							if ! Validate_Number "$cruminstmp3"
							then
								printf "\\n${ERR}Please enter a valid number (0-30)${CLEARFORMAT}\\n"
								cruminsvalidated="false"
								break
							elif [ "$cruminstmp3" -lt 0 ] || [ "$cruminstmp3" -gt 30 ]
							then
								printf "\\n${ERR}Please enter a number between 0 and 30${CLEARFORMAT}\\n"
								cruminsvalidated="false"
								break
							fi
						elif ! Validate_Number "$i"
						then
							printf "\\n${ERR}Please enter a valid number (0-59) or comma separated values${CLEARFORMAT}\\n"
							cruminsvalidated="false"
							break
						elif [ "$i" -lt 0 ] || [ "$i" -gt 59 ]
						then
							printf "\\n${ERR}Please enter a number between 0 and 59 or comma separated values${CLEARFORMAT}\\n"
							cruminsvalidated="false"
							break
						fi
					done
					
					if [ "$cruminsvalidated" = "true" ]
					then
						if echo "$min_choice" | grep -q "-"
						then
							crumins1="$(echo "$min_choice" | cut -f1 -d'-')"
							crumins2="$(echo "$min_choice" | cut -f2 -d'-')"
							if [ "$crumins1" -lt "$crumins2" ]
							then
								crumins="$min_choice"
							elif [ "$crumins2" -lt "$crumins1" ]
							then
								crumins="$crumins1-59,0-$crumins2"
							fi
						else
							crumins="$min_choice"
						fi
						printf "\n"
						break
					fi
				fi
			done
		fi
	fi
	
	if [ "$exitmenu" != "exit" ]
    then
		CronTestSchedule update "$crudays" "$cruhours" "$crumins"
		return 0
	else
		return 1
	fi
}

Menu_ResetDB()
{
	printf "${BOLD}${WARN}WARNING: This will reset the %s database by deleting all database records.\n" "$SCRIPT_NAME"
	printf "A backup of the database will be created if you change your mind.${CLEARFORMAT}\n"
	printf "\n${BOLD}Do you want to continue? (y/n)${CLEARFORMAT}  "
	read -r confirm
	case "$confirm" in
		y|Y)
			printf "\n"
			Reset_DB
		;;
		*)
			printf "\n${BOLD}${WARN}Database reset cancelled${CLEARFORMAT}\n\n"
		;;
	esac
}

##----------------------------------------##
## Modified by Martinski W. [2025-Jun-06] ##
##----------------------------------------##
Menu_AutoBW()
{
	local AUTOBW_MenuStatus

	while true
	do
		ScriptHeader

		AUTOBW_MenuStatus="UNKNOWN"

		if [ "$(AutoBWEnable check)" = "true" ]
		then
			AUTOBW_MenuStatus="${PassBGRNct} ENABLED ${CLRct}"
		elif [ "$(AutoBWEnable check)" = "false" ]
		then
			AUTOBW_MenuStatus="${CritIREDct} DISABLED ${CLRct}"
		fi

		printf "1.    Update QoS bandwidth values now\n\n"
		printf "2.    Configure number of speedtests used to calculate average bandwidth\n"
		printf "      Currently bandwidth is calculated using the average of the last ${SETTING}%s${CLEARFORMAT} speedtest(s)\n\n" "$(AutoBWConf check AVERAGE CALC)"
		printf "3.    Configure scale factor\n"
		printf "      Download: ${SETTING}%s%%${CLEARFORMAT}  -  Upload: ${SETTING}%s%%${CLEARFORMAT}\n\n" "$(AutoBWConf check SF DOWN)" "$(AutoBWConf check SF UP)"
		printf "4.    Configure bandwidth limits\n"
		printf "      Upper Limit    Download: ${SETTING}%s Mbps${CLEARFORMAT}  -  Upload: ${SETTING}%s Mbps${CLEARFORMAT}\n" "$(AutoBWConf check ULIMIT DOWN)" "$(AutoBWConf check ULIMIT UP)"
		printf "      Lower Limit    Download: ${SETTING}%s Mbps${CLEARFORMAT}  -  Upload: ${SETTING}%s Mbps${CLEARFORMAT}\n\n" "$(AutoBWConf check LLIMIT DOWN)" "$(AutoBWConf check LLIMIT UP)"
		printf "5.    Configure threshold for updating QoS bandwidth values\n"
		printf "      Download: ${SETTING}%s%%${CLEARFORMAT} - Upload: ${SETTING}%s%%${CLEARFORMAT}\n\n" "$(AutoBWConf check THRESHOLD DOWN)" "$(AutoBWConf check THRESHOLD UP)"
		printf "6.    Toggle AutoBW on/off\n"
		printf "      Currently: ${AUTOBW_MenuStatus}${CLEARFORMAT}\n\n"
		printf "e.    Go back\n\n"
		printf "${BOLD}####################################################################${CLEARFORMAT}\n"
		printf "\n"

		printf "Choose an option:  "
		read -r autobwmenu
		case "$autobwmenu" in
			1)
				printf "\\n"
				Menu_AutoBW_Update
				PressEnter
			;;
			2)
				while true
				do
					ScriptHeader
					exitmenu=""
					avgnum=""
					while true
					do
						printf "\\n"
						printf "Enter number of speedtests to use to calculate avg bandwidth (1-30):  "
						read -r avgnumvalue
							if [ "$avgnumvalue" = "e" ]; then
								exitmenu="exit"
								break
							elif ! Validate_Number "$avgnumvalue"; then
								printf "\\n${ERR}Please enter a valid number (1-30)${CLEARFORMAT}\\n"
							else
								if [ "$avgnumvalue" -lt 1 ] || [ "$avgnumvalue" -gt 30 ]; then
									printf "\\n${ERR}Please enter a number between 1 and 30${CLEARFORMAT}\\n"
								else
									avgnum="$avgnumvalue"
									break
								fi
							fi
					done
					if [ "$exitmenu" != "exit" ]; then
						AutoBWConf update AVERAGE CALC "$avgnum"
						break
					fi
					if [ "$exitmenu" = "exit" ]; then
						break
					fi
				done
				printf "\\n"
				PressEnter
			;;
			3)
				while true
				do
					ScriptHeader
					exitmenu=""
					updown=""
					sfvalue=""
					printf "\\n"
					printf "Select a scale factor to set\\n"
					printf "1.    Download\\n"
					printf "2.    Upload\\n\\n"
					while true
					do
						printf "Choose an option:  "
						read -r autobwsfchoice
						if [ "$autobwsfchoice" = "e" ]; then
							exitmenu="exit"
							break
						elif ! Validate_Number "$autobwsfchoice"; then
							printf "\\n${ERR}Please enter a valid number (1-2)${CLEARFORMAT}\\n\\n"
						else
							if [ "$autobwsfchoice" -lt 1 ] || [ "$autobwsfchoice" -gt 2 ]; then
								printf "\\n${ERR}Please enter a number between 1 and 2${CLEARFORMAT}\\n\\n"
							else
								if [ "$autobwsfchoice" -eq 1 ]; then
									updown="DOWN"
									break
								elif [ "$autobwsfchoice" -eq 2 ]; then
									updown="UP"
									break
								fi
							fi
						fi
					done
					if [ "$exitmenu" != "exit" ]
					then
						while true
						do
							printf "\\n"
							printf "Enter percentage to scale bandwidth by (1-100):  "
							read -r autobwsfvalue
								if [ "$autobwsfvalue" = "e" ]; then
									exitmenu="exit"
									break
								elif ! Validate_Number "$autobwsfvalue"; then
									printf "\\n${ERR}Please enter a valid number (1-100)${CLEARFORMAT}\\n"
								else
									if [ "$autobwsfvalue" -lt 1 ] || [ "$autobwsfvalue" -gt 100 ]; then
										printf "\\n${ERR}Please enter a number between 1 and 100${CLEARFORMAT}\\n"
									else
										sfvalue="$autobwsfvalue"
										break
									fi
								fi
						done
					fi
					if [ "$exitmenu" != "exit" ]; then
						AutoBWConf update SF "$updown" "$sfvalue"
						break
					fi
					
					if [ "$exitmenu" = "exit" ]; then
						break
					fi
				done
				
				printf "\\n"
				PressEnter
			;;
			4)
				while true
				do
					ScriptHeader
					exitmenu=""
					updown=""
					limithighlow=""
					limitvalue=""
					printf "\\n"
					printf "Select a bandwidth to set limit for\\n"
					printf "1.    Download\\n"
					printf "2.    Upload\\n\\n"
					while true
					do
						printf "Choose an option:  "
						read -r autobwchoice
						if [ "$autobwchoice" = "e" ]; then
							exitmenu="exit"
							break
						elif ! Validate_Number "$autobwchoice"; then
							printf "\\n${ERR}Please enter a valid number (1-2)${CLEARFORMAT}\\n\\n"
						else
							if [ "$autobwchoice" -lt 1 ] || [ "$autobwchoice" -gt 2 ]; then
								printf "\\n${ERR}Please enter a number between 1 and 2${CLEARFORMAT}\\n\\n"
							else
								if [ "$autobwchoice" -eq 1 ]; then
									updown="DOWN"
									break
								elif [ "$autobwchoice" -eq 2 ]; then
									updown="UP"
									break
								fi
							fi
						fi
					done
					if [ "$exitmenu" != "exit" ]
					then
						while true
						do
							printf "\\n"
							printf "Select a limit to set\\n"
							printf "1.    Upper\\n"
							printf "2.    Lower\\n\\n"
							printf "Choose an option:  "
							read -r autobwlimit
								if [ "$autobwlimit" = "e" ]; then
									exitmenu="exit"
									break
								elif ! Validate_Number "$autobwlimit"; then
									printf "\\n${ERR}Please enter a valid number (1-100)${CLEARFORMAT}\\n"
								else
									if [ "$autobwlimit" -lt 1 ] || [ "$autobwlimit" -gt 100 ]; then
										printf "\\n${ERR}Please enter a number between 1 and 100${CLEARFORMAT}\\n"
									else
										if [ "$autobwlimit" -eq 1 ]; then
											limithighlow="ULIMIT"
										elif [ "$autobwlimit" -eq 2 ]; then
											limithighlow="LLIMIT"
										fi
									fi
								fi
								
								if [ "$exitmenu" != "exit" ]
								then
									while true
									do
										printf "\\n"
										printf "Enter value to set limit to (0 = unlimited for upper):  "
										read -r autobwlimvalue
										if [ "$autobwlimvalue" = "e" ]; then
											exitmenu="exit"
											break
										elif ! Validate_Number "$autobwlimvalue"; then
											printf "\\n${ERR}Please enter a valid number (1-100)${CLEARFORMAT}\\n"
										else
											limitvalue="$autobwlimvalue"
											break
										fi
									done
									if [ "$exitmenu" != "exit" ]; then
										AutoBWConf update "$limithighlow" "$updown" "$limitvalue"
										exitmenu="exit"
										break
									fi
								fi
						done
						if [ "$exitmenu" = "exit" ]; then
							break
						fi
					fi
				done
				
				printf "\\n"
				PressEnter
			;;
			5)
				while true
				do
					ScriptHeader
					exitmenu=""
					updown=""
					thvalue=""
					printf "\\n"
					printf "Select a threshold to set\\n"
					printf "1.    Download\\n"
					printf "2.    Upload\\n\\n"
					while true
					do
						printf "Choose an option:  "
						read -r autobwthchoice
						if [ "$autobwthchoice" = "e" ]; then
							exitmenu="exit"
							break
						elif ! Validate_Number "$autobwthchoice"; then
							printf "\\n${ERR}Please enter a valid number (1-2)${CLEARFORMAT}\\n\\n"
						else
							if [ "$autobwthchoice" -lt 1 ] || [ "$autobwthchoice" -gt 2 ]; then
								printf "\\n${ERR}Please enter a number between 1 and 2${CLEARFORMAT}\\n\\n"
							else
								if [ "$autobwthchoice" -eq 1 ]; then
									updown="DOWN"
									break
								elif [ "$autobwthchoice" -eq 2 ]; then
									updown="UP"
									break
								fi
							fi
						fi
					done
					
					if [ "$exitmenu" != "exit" ]
					then
						while true
						do
							printf "\\n"
							printf "Enter percentage to use for result threshold:  "
							read -r autobwthvalue
							if [ "$autobwthvalue" = "e" ]; then
								exitmenu="exit"
								break
							elif ! Validate_Number "$autobwthvalue"; then
								printf "\\n${ERR}Please enter a valid number (0-100)${CLEARFORMAT}\\n"
							else
								if [ "$autobwthvalue" -lt 0 ] || [ "$autobwthvalue" -gt 100 ]; then
									printf "\\n${ERR}Please enter a number between 0 and 100${CLEARFORMAT}\\n"
								else
									thvalue="$autobwthvalue"
									break
								fi
							fi
						done
					fi
					
					if [ "$exitmenu" != "exit" ]; then
						AutoBWConf update THRESHOLD "$updown" "$thvalue"
						break
					fi
					
					if [ "$exitmenu" = "exit" ]; then
						break
					fi
				done
				
				printf "\\n"
				PressEnter
			;;
			6)
				printf "\n"
				if [ "$(AutoBWEnable check)" = "true" ]
				then
					AutoBWEnable disable
				elif [ "$(AutoBWEnable check)" = "false" ]
				then
					AutoBWEnable enable
					if [ "$(ExcludeFromQoS check)" = "false" ]
					then
						Print_Output false "Enabling Exclude from QoS (required for AutoBW)"
						ExcludeFromQoS enable
						PressEnter
					fi
				fi
			;;
			e)
				break
			;;
		esac
	done
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Menu_AutoBW_Update()
{
	if [ "$(nvram get qos_enable)" -eq 0 ]
	then
		Print_Output true "QoS is not enabled, please enable this in the Asus WebUI." "$ERR"
		return 1
	fi

	dsf="$(AutoBWConf check SF DOWN | awk '{printf ($1/100)}')"
	usf="$(AutoBWConf check SF UP | awk '{printf ($1/100)}')"

	dlimitlow="$(($(AutoBWConf check LLIMIT DOWN)*1024))"
	dlimithigh="$(($(AutoBWConf check ULIMIT DOWN)*1024))"
	ulimitlow="$(($(AutoBWConf check LLIMIT UP)*1024))"
	ulimithigh="$(($(AutoBWConf check ULIMIT UP)*1024))"
	avgcalc="$(AutoBWConf check AVERAGE CALC)"

	metriclist="Download Upload"
	local abwIndx=0
	for metric in $metriclist
	do
	{
		{
		   echo ".mode list"
		   echo ".headers off"
		   echo ".output /tmp/spdbw$metric"
		   echo "PRAGMA temp_store=1;"
		   echo "SELECT avg($metric) FROM (SELECT $metric FROM spdstats_WAN ORDER BY [Timestamp] DESC LIMIT $avgcalc);"
		} > /tmp/spdTest-autobw.sql
		abwIndx="$((abwIndx + 1))"
		_ApplyDatabaseSQLCmds_ /tmp/spdTest-autobw.sql "abw${abwIndx}"
		rm -f /tmp/spdTest-autobw.sql
	}
	done

	autobwoutfile="$SCRIPT_STORAGE_DIR/.autobwoutfile"
	TZ="$(cat /etc/TZ)"
	export TZ

	printf "AutoBW report - %s\\n\\n" "$(date +'%c')" > "$autobwoutfile"

	dspdkbps="$(echo "$(awk '{printf (1024*$1)}' /tmp/spdbwDownload)" "$dsf" | awk '{printf int($1*$2)}')"
	uspdkbps="$(echo "$(awk '{printf (1024*$1)}' /tmp/spdbwUpload)" "$usf" | awk '{printf int($1*$2)}')"

	rm -f /tmp/spdbwDownload
	rm -f /tmp/spdbwUpload

	if [ "$dspdkbps" -lt "$dlimitlow" ]
	then
		Print_Output true "Download speed ($dspdkbps Kbps) < lower limit ($dlimitlow Kbps)" "$WARN" | tee -a "$autobwoutfile"
		dspdkbps="$dlimitlow"
	elif [ "$dspdkbps" -gt "$dlimithigh" ] && [ "$dlimithigh" -gt 0 ]
	then
		Print_Output true "Download speed ($dspdkbps Kbps) > upper limit ($dlimithigh Kbps)" "$WARN" | tee -a "$autobwoutfile"
		dspdkbps="$dlimithigh"
	fi

	if [ "$uspdkbps" -lt "$ulimitlow" ]
	then
		Print_Output true "Upload speed ($uspdkbps Kbps) < lower limit ($ulimitlow Kbps)" "$WARN" | tee -a "$autobwoutfile"
		uspdkbps="$ulimitlow"
	elif [ "$uspdkbps" -gt "$ulimithigh" ] && [ "$ulimithigh" -gt 0 ]
	then
		Print_Output true "Upload speed ($uspdkbps Kbps) > upper limit ($ulimithigh Kbps)" "$WARN" | tee -a "$autobwoutfile"
		uspdkbps="$ulimithigh"
	fi

	old_uspdkbps="$(nvram get qos_obw)"
	old_dspdkbps="$(nvram get qos_ibw)"

	bw_changed="false"

	dbw_threshold="$(AutoBWConf check THRESHOLD DOWN | awk '{printf ($1/100)}')"

	if [ "$dspdkbps" -gt "$(echo "$old_dspdkbps" "$dbw_threshold" | awk '{printf int($1+$1*$2)}')" ] || \
	   [ "$dspdkbps" -lt "$(echo "$old_dspdkbps" "$dbw_threshold" | awk '{printf int($1-$1*$2)}')" ]
	then
		bw_changed="true"
		nvram set qos_ibw="$(echo $dspdkbps | cut -d'.' -f1)"
		Print_Output true "Setting QoS Download Speed to $dspdkbps Kbps (was $old_dspdkbps Kbps)" "$PASS" | tee -a "$autobwoutfile"
	else
		Print_Output true "Calculated Download speed ($dspdkbps Kbps) does not exceed $(AutoBWConf check THRESHOLD DOWN)% threshold of existing value ($old_dspdkbps Kbps)" "$WARN" | tee -a "$autobwoutfile"
	fi

	ubw_threshold="$(AutoBWConf check THRESHOLD UP | awk '{printf ($1/100)}')"

	if [ "$uspdkbps" -gt "$(echo "$old_uspdkbps" "$ubw_threshold" | awk '{printf int($1+$1*$2)}')" ] || \
	   [ "$uspdkbps" -lt "$(echo "$old_uspdkbps" "$ubw_threshold" | awk '{printf int($1-$1*$2)}')" ]
	then
		bw_changed="true"
		nvram set qos_obw="$(echo $uspdkbps | cut -d'.' -f1)"
		Print_Output true "Setting QoS Upload Speed to $uspdkbps Kbps (was $old_uspdkbps Kbps)" "$PASS" | tee -a "$autobwoutfile"
	else
		Print_Output true "Calculated Upload speed ($uspdkbps Kbps) does not exceed $(AutoBWConf check THRESHOLD UP)% threshold of existing value ($old_uspdkbps Kbps)" "$WARN" | tee -a "$autobwoutfile"
	fi

	if [ "$bw_changed" = "true" ]
	then
		nvram commit
		service "restart_qos;restart_firewall" >/dev/null 2>&1
		printf "AutoBW made changes to QoS bandwidth, QoS will be restarted" >> "$autobwoutfile"
	else
		printf "No changes made to QoS by AutoBW" >> "$autobwoutfile"
	fi

	sed -i 's/[^a-zA-Z0-9():%<>-]/ /g;s/  1m//g;s/  33m//g;s/  0m//g' "$autobwoutfile"

	Clear_Lock
}

##-------------------------------------##
## Added by Martinski W. [2025-Mar-01] ##
##-------------------------------------##
_RemoveMenuAddOnsSection_()
{
   if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ] || \
      ! echo "$1" | grep -qE "^[1-9][0-9]*$" || \
      ! echo "$2" | grep -qE "^[1-9][0-9]*$" || \
      [ "$1" -ge "$2" ]
   then return 1 ; fi
   local BEGINnum="$1"  ENDINnum="$2"

   if [ -n "$(sed -E "${BEGINnum},${ENDINnum}!d;/${webPageLineTabExp}/!d" "$TEMP_MENU_TREE")" ]
   then return 1
   fi
   sed -i "${BEGINnum},${ENDINnum}d" "$TEMP_MENU_TREE"
   return 0
}

##-------------------------------------##
## Added by Martinski W. [2025-Mar-01] ##
##-------------------------------------##
_FindandRemoveMenuAddOnsSection_()
{
   local BEGINnum  ENDINnum  retCode=1

   if grep -qE "^${BEGIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE" && \
      grep -qE "^${ENDIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE"
   then
       BEGINnum="$(grep -nE "^${BEGIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       ENDINnum="$(grep -nE "^${ENDIN_MenuAddOnsTag}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       _RemoveMenuAddOnsSection_ "$BEGINnum" "$ENDINnum" && retCode=0
   fi

   if grep -qE "^${webPageMenuAddons}$" "$TEMP_MENU_TREE" && \
      grep -qE "${webPageHelpSupprt}$" "$TEMP_MENU_TREE"
   then
       BEGINnum="$(grep -nE "^${webPageMenuAddons}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       ENDINnum="$(grep -nE "${webPageHelpSupprt}$" "$TEMP_MENU_TREE" | awk -F ':' '{print $1}')"
       if [ -n "$BEGINnum" ] && [ -n "$ENDINnum" ] && [ "$BEGINnum" -lt "$ENDINnum" ]
       then
           BEGINnum="$((BEGINnum - 2))" ; ENDINnum="$((ENDINnum + 3))"
           if [ "$(sed -n "${BEGINnum}p" "$TEMP_MENU_TREE")" = "," ] && \
              [ "$(sed -n "${ENDINnum}p" "$TEMP_MENU_TREE")" = "}" ]
           then
               _RemoveMenuAddOnsSection_ "$BEGINnum" "$ENDINnum" && retCode=0
           fi
       fi
   fi
   return "$retCode"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Apr-30] ##
##----------------------------------------##
Menu_Uninstall()
{
	if [ -n "$PPID" ]; then
		ps | grep -v grep | grep -v $$ | grep -v "$PPID" | grep -i "$SCRIPT_NAME_LOWER" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	else
		ps | grep -v grep | grep -v $$ | grep -i "$SCRIPT_NAME_LOWER" | grep generate | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
	fi

	SPEEDTEST_BINARY=""
	if [ "$(SpeedtestBinary check)" = "builtin" ]
	then
		SPEEDTEST_BINARY=/usr/sbin/ookla
	elif [ "$(SpeedtestBinary check)" = "external" ]
	then
		SPEEDTEST_BINARY="$OOKLA_DIR/speedtest"
	fi
	PROC_NAME="speedtest"
	if [ "$SPEEDTEST_BINARY" = "/usr/sbin/ookla" ]; then
		PROC_NAME="ookla"
	fi
	if [ -n "$(pidof "$PROC_NAME")" ]; then
		killall -q "$PROC_NAME"
	fi
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	Shortcut_Script delete

	LOCKFILE=/tmp/addonwebui.lock
	FD=386
	eval exec "$FD>$LOCKFILE"
	flock -x "$FD"

	Get_WebUI_Page "$SCRIPT_DIR/spdstats_www.asp"
	if [ -n "$MyWebPage" ] && \
	   [ "$MyWebPage" != "NONE" ] && \
	   [ -f "$TEMP_MENU_TREE" ]
	then
		sed -i "\\~$MyWebPage~d" "$TEMP_MENU_TREE"
		rm -f "$SCRIPT_WEBPAGE_DIR/$MyWebPage"
		rm -f "$SCRIPT_WEBPAGE_DIR/$(echo "$MyWebPage" | cut -f1 -d'.').title"
		_FindandRemoveMenuAddOnsSection_
		umount /www/require/modules/menuTree.js
		mount -o bind "$TEMP_MENU_TREE" /www/require/modules/menuTree.js
	fi

	flock -u "$FD"
	rm -f "$SCRIPT_DIR/spdstats_www.asp" 2>/dev/null

	printf "\n${BOLD}Do you want to delete %s stats and config? (y/n)${CLEARFORMAT}  " "$SCRIPT_NAME"
	read -r confirm
	case "$confirm" in
		y|Y)
			rm -rf "$SCRIPT_DIR" 2>/dev/null
			rm -rf "$SCRIPT_STORAGE_DIR" 2>/dev/null
		;;
		*)
			:
		;;
	esac

	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	sed -i '/spdmerlin_version_local/d' "$SETTINGSFILE"
	sed -i '/spdmerlin_version_server/d' "$SETTINGSFILE"

	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	rm -rf "$OOKLA_DIR" 2>/dev/null
	rm -rf "$OOKLA_LICENSE_DIR" 2>/dev/null
	rm -f "/jffs/scripts/$SCRIPT_NAME_LOWER" 2>/dev/null
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
NTP_Ready()
{
	local theSleepDelay=15  ntpMaxWaitSecs=600  ntpWaitSecs

	if [ "$(nvram get ntp_ready)" -eq 0 ]
	then
		Check_Lock
		ntpWaitSecs=0
		Print_Output true "Waiting for NTP to sync..." "$WARN"

		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpWaitSecs" -lt "$ntpMaxWaitSecs" ]
		do
			if [ "$ntpWaitSecs" -gt 0 ] && [ "$((ntpWaitSecs % 30))" -eq 0 ]
			then
			    Print_Output true "Waiting for NTP to sync [$ntpWaitSecs secs]..." "$WARN"
			fi
			sleep "$theSleepDelay"
			ntpWaitSecs="$((ntpWaitSecs + theSleepDelay))"
		done
		if [ "$ntpWaitSecs" -ge "$ntpMaxWaitSecs" ]
		then
			Print_Output true "NTP failed to sync after 10 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "NTP synced, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
Entware_Ready()
{
	local theSleepDelay=5  maxSleepTimer=120  sleepTimerSecs

	if [ ! -f /opt/bin/opkg ]
	then
		Check_Lock
		sleepTimerSecs=0

		while [ ! -f /opt/bin/opkg ] && [ "$sleepTimerSecs" -lt "$maxSleepTimer" ]
		do
			if [ "$((sleepTimerSecs % 10))" -eq 0 ]
			then
			    Print_Output true "Entware NOT found. Wait for Entware to be ready [$sleepTimerSecs secs]..." "$WARN"
			fi
			sleep "$theSleepDelay"
			sleepTimerSecs="$((sleepTimerSecs + theSleepDelay))"
		done
		if [ ! -f /opt/bin/opkg ]
		then
			Print_Output true "Entware NOT found and is required for $SCRIPT_NAME to run, please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "Entware found. $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @dave14305's FlexQoS about function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Jun-04] ##
##----------------------------------------##
Show_About()
{
	cat <<EOF
About $SCRIPT_VERS_INFO
  $SCRIPT_NAME is an internet speedtest and monitoring tool for
  AsusWRT Merlin with charts for daily, weekly and monthly summaries.
  It tracks download/upload bandwidth as well as latency, jitter and
  packet loss.

License
  $SCRIPT_NAME is free to use under the GNU General Public License
  version 3 (GPL-3.0) https://opensource.org/licenses/GPL-3.0

Help & Support
  https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=19

Source code
  https://github.com/AMTM-OSR/$SCRIPT_NAME
EOF
	printf "\n"
}

### function based on @dave14305's FlexQoS show_help function ###
##----------------------------------------##
## Modified by Martinski W. [2025-Jun-04] ##
##----------------------------------------##
Show_Help()
{
	cat <<EOF
HELP $SCRIPT_VERS_INFO
Available commands:
  $SCRIPT_NAME_LOWER about            explains functionality
  $SCRIPT_NAME_LOWER update           checks for updates
  $SCRIPT_NAME_LOWER forceupdate      updates to latest version (force update)
  $SCRIPT_NAME_LOWER startup force    runs startup actions such as mount WebUI tab
  $SCRIPT_NAME_LOWER install          installs script
  $SCRIPT_NAME_LOWER uninstall        uninstalls script
  $SCRIPT_NAME_LOWER generate         run speedtest and save to database. also runs outputcsv
  $SCRIPT_NAME_LOWER outputcsv        create CSVs from database, used by WebUI and export
  $SCRIPT_NAME_LOWER enable           enable automatic speedtests
  $SCRIPT_NAME_LOWER disable          disable automatic speedtests
  $SCRIPT_NAME_LOWER develop          switch to development branch
  $SCRIPT_NAME_LOWER stable           switch to stable branch
EOF
	printf "\n"
}

##-------------------------------------##
## Added by Martinski W. [2025-Jan-04] ##
##-------------------------------------##
TMPDIR="$SHARE_TEMP_DIR"
SQLITE_TMPDIR="$TMPDIR"
export SQLITE_TMPDIR TMPDIR

if [ -d "$TMPDIR" ]
then sqlDBLogFilePath="${TMPDIR}/$sqlDBLogFileName"
else sqlDBLogFilePath="/tmp/var/tmp/$sqlDBLogFileName"
fi
_SQLCheckDBLogFileSize_

if [ -f "/opt/share/${SCRIPT_NAME_LOWER}.d/config" ]
then SCRIPT_STORAGE_DIR="/opt/share/${SCRIPT_NAME_LOWER}.d"
else SCRIPT_STORAGE_DIR="/jffs/addons/${SCRIPT_NAME_LOWER}.d"
fi

SCRIPT_CONF="$SCRIPT_STORAGE_DIR/config"
SPEEDSTATS_DB="$SCRIPT_STORAGE_DIR/spdstats.db"
CSV_OUTPUT_DIR="$SCRIPT_STORAGE_DIR/csv"
SCRIPT_INTERFACES="$SCRIPT_STORAGE_DIR/.interfaces"
SCRIPT_INTERFACES_USER="$SCRIPT_STORAGE_DIR/.interfaces_user"
JFFS_LowFreeSpaceStatus="OK"

if [ "$SCRIPT_BRANCH" != "develop" ]
then SCRIPT_VERS_INFO=""
else SCRIPT_VERS_INFO="$scriptVERINFO"
fi

##----------------------------------------##
## Modified by Martinski W. [2025-Feb-28] ##
##----------------------------------------##
if [ $# -eq 0 ] || [ -z "$1" ]
then
	NTP_Ready
	Entware_Ready
	if [ ! -f /opt/bin/sqlite3 ] && [ -x /opt/bin/opkg ]
	then
		Print_Output true "Installing required version of sqlite3 from Entware" "$PASS"
		opkg update
		opkg install sqlite3-cli
	fi

	Create_Dirs
	Conf_Exists
	if [ "$(SpeedtestBinary check)" = "builtin" ]
	then
		printf "/usr/sbin/ookla" > /tmp/spdmerlin-binary
	elif [ "$(SpeedtestBinary check)" = "external" ]
	then
		printf "%s" "$OOKLA_DIR/speedtest" > /tmp/spdmerlin-binary
	fi
	ScriptStorageLocation load
	Create_Symlinks

	Process_Upgrade

	Auto_Startup create 2>/dev/null
	if AutomaticMode check
	then Auto_Cron create 2>/dev/null
	else Auto_Cron delete 2>/dev/null
	fi
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_Script create
	_CheckFor_WebGUI_Page_
	ScriptHeader
	MainMenu
	exit 0
fi

##----------------------------------------##
## Modified by Martinski W. [2025-Jan-19] ##
##----------------------------------------##
case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	startup)
		Menu_Startup "$2"
		exit 0
	;;
	generate)
		NTP_Ready
		Entware_Ready
		Check_Lock
		Run_Speedtest schedule
		Clear_Lock
		exit 0
	;;
	trimdb)
		NTP_Ready
		Entware_Ready
		Check_Lock
		_Trim_Database_
		_Optimize_Database_
		_UpdateDatabaseFileSizeInfo_
		Clear_Lock
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && echo "$3" | grep -q "${SCRIPT_NAME_LOWER}spdtest"
		then
			rm -f /tmp/detect_spdtest.js
			rm -f /tmp/spd-result.txt
			rm -f /tmp/spd-stats.txt
			Check_Lock webui
			sleep 3
			Run_Speedtest_WebUI "$3"
			Clear_Lock
		elif [ "$2" = "start" ] && echo "$3" | grep -q "${SCRIPT_NAME_LOWER}serverlistmanual"
		then
			spdifacename="$(echo "$3" | sed "s/${SCRIPT_NAME_LOWER}serverlistmanual_//" | cut -f1 -d'_' | tr "a-z" "A-Z")";
			GenerateServerList_WebUI "$spdifacename" "spdmerlin_manual_serverlist"
		elif [ "$2" = "start" ] && echo "$3" | grep -q "${SCRIPT_NAME_LOWER}serverlist"
		then
			spdifacename="$(echo "$3" | sed "s/${SCRIPT_NAME_LOWER}serverlist_//" | cut -f1 -d'_' | tr "a-z" "A-Z")";
			GenerateServerList_WebUI "$spdifacename" "spdmerlin_serverlist_$spdifacename"
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME_LOWER}config" ]
		then
			Interfaces_FromSettings
			Conf_FromSettings
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME_LOWER}checkupdate" ]
		then
			Update_Check
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME_LOWER}doupdate" ]
		then
			Update_Version force unattended
		fi
		exit 0
	;;
	outputcsv)
		NTP_Ready
		Entware_Ready
		Check_Lock
		Generate_CSVs
		Clear_Lock
		exit 0
	;;
	enable)
		Entware_Ready
		AutomaticMode enable
		exit 0
	;;
	disable)
		Entware_Ready
		AutomaticMode disable
		exit 0
	;;
	update)
		Update_Version
		exit 0
	;;
	forceupdate)
		Update_Version force
		exit 0
	;;
	postupdate)
		Create_Dirs
		Conf_Exists
		if [ "$(SpeedtestBinary check)" = "builtin" ]; then
			printf "/usr/sbin/ookla" > /tmp/spdmerlin-binary
		elif [ "$(SpeedtestBinary check)" = "external" ]; then
			printf "%s" "$OOKLA_DIR/speedtest" > /tmp/spdmerlin-binary
		fi
		ScriptStorageLocation load
		Create_Symlinks
		Process_Upgrade
		Auto_Startup create 2>/dev/null
		if AutomaticMode check
		then Auto_Cron create 2>/dev/null
		else Auto_Cron delete 2>/dev/null
		fi
		Auto_ServiceEvent create 2>/dev/null
		Shortcut_Script create
		Set_Version_Custom_Settings local "$SCRIPT_VERSION"
		Set_Version_Custom_Settings server "$SCRIPT_VERSION"
		exit 0
	;;
	checkupdate)
		Update_Check
		exit 0
	;;
	uninstall)
		Menu_Uninstall
		exit 0
	;;
	develop)
		SCRIPT_BRANCH="develop"
		SCRIPT_REPO="https://raw.githubusercontent.com/AMTM-OSR/$SCRIPT_NAME/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	stable)
		SCRIPT_BRANCH="master"
		SCRIPT_REPO="https://raw.githubusercontent.com/AMTM-OSR/$SCRIPT_NAME/$SCRIPT_BRANCH"
		Update_Version force
		exit 0
	;;
	about)
		ScriptHeader
		Show_About
		exit 0
	;;
	help)
		ScriptHeader
		Show_Help
		exit 0
	;;
	*)
		ScriptHeader
		Print_Output false "Parameter [$*] is NOT recognised." "$ERR"
		Print_Output false "For a list of available commands run: $SCRIPT_NAME_LOWER help" "$SETTING"
		exit 1
	;;
esac
