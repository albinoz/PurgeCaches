#!/bin/bash
clear

( #Logs Begin
exec &> >(while read -r line; do echo "$(date +"[%Y-%m-%d_%H:%M:%S]") $line"; done;) #Date to Every Line
OSX=$(sw_vers -productVersion | cut -d'.' -f2)
if [ "$OSX" -le 6 ] ; then exit ; fi #Exit if OSX < 10.6
if [ "$OSX" -ge 9 ] ; then #Disable Emoji if OSX < 10.9
if date +%m | grep 12 > /dev/null ; then Icon="🎄 " ; else Icon="📌 " ; fi #Christmas
Lock="🔒 " && UnLock="🔓 "
else Icon="=->" && Lock="=->" && UnLock="=->"
fi

echo "Purge Caches"
echo "adam | 2019-10-18"
echo "10.6 < 10.15 Tested"

echo; date
echo "$(hostname)" - "$(whoami)" - "$(sw_vers -productVersion)"
fdesetup status
if [ "$OSX" -ge 11 ] ; then csrutil status ; fi
uptime

echo; echo "$Icon" 'Eject Volumes'
df | grep Volumes | awk '{ print $1 }' | while read disk; do diskutil unmount "$disk"; done

if echo; echo "$Lock" 'Purge Caches' ; echo 'Require Administrator Privileges :' ; sudo echo "$UnLock" 'You Shall Pass' | grep Shall ; then echo; else exit ; fi

echo; echo "$Icon" 'Check Boot Disk SMART :' && sleep 3
if diskutil info disk0 | grep SMART | grep Verified ; then echo SMART OK; else echo SMART Error && exit ; fi

echo; echo "$Icon" 'Check Disk Previous I/O Errors :' && sleep 3
if cat /var/log/system.log | grep 'I/O' | grep -v disabling ; then echo 'Disk I/O Errors, Rescue & Change Disk' && sleep 15 ; else echo "No Disk Previous I/O Errors Found" ; fi

echo; echo "$Icon" 'Check Boot Disk Tree :' && sleep 3
sudo diskutil verifyvolume / | tee /tmp/CheckDiskTree.txt
if cat /tmp/CheckDiskTree.txt | grep OK ; then echo Disk Tree OK ; else echo Disk Tree Error, Need Repair && exit ; fi

if [ "$OSX" -ge 7 ] ; then
echo; echo "$Icon" 'Purge RAM :' && sleep 3
sudo purge
fi

echo; echo "$Icon" 'Purge VM :' && sleep 3
sudo rm -vfr /var/vm/*

echo; echo "$Icon" 'Purge DNS Cache :' && sleep 3
sudo dscacheutil -flushcache

echo; echo "$Icon" 'Script Maintenance :' && sleep 3
sudo /usr/sbin/periodic daily weekly monthly

if [ "$OSX" -le 14 ] ; then
echo; echo "$Icon" 'Repair Permissions :' && sleep 3
if [ "$OSX" -ge 9 ]
then echo "OSX≥10.9 > External Repair" ;
	if test -f /usr/local/bin/RepairPermissions
	then sudo /usr/local/bin/RepairPermissions / --output /tmp/RepairPermissionsResult.txt / ; sleep 1 & cat /tmp/RepairPermissionsResult.txt
		else sudo mkdir -p /usr/local/bin/
		sudo chown -R "$(whoami)" /usr/local/bin/
		cd /tmp && curl -O https://raw.githubusercontent.com/Austere-J/RepoRepairPermissions/master/RepairPermissions3.9.3225_870c5cd76ea7c7f462a33ba574b0693a.zip
		unzip /tmp/*.zip
		sudo chmod 755 /tmp/RepairPermissions
		cp -vpfr /tmp/RepairPermissions /usr/local/bin/RepairPermissions
		sudo /usr/local/bin/RepairPermissions --output /tmp/RepairPermissionsResult.txt ; sleep 1 & cat /tmp/RepairPermissionsResult.txt
	fi
	else echo "OSX≤10.9 > Internal Repair"
	diskutil repairPermissions /
fi
else echo && echo "$Icon" 'Bypass Repair Permissions' ; fi

# Fix Potential Not Write /tmp
sudo chmod 1777 /private/tmp


if [ "$OSX" -ge 7 ]
then
echo; echo "$Icon" 'Purge Old OS Classic :' && sleep 3
rm -vrf '/System Folder'
rm -vrf '/Dossier Système'
rm -vrf '/Applications (Mac OS 9)'
rm -vrf '/Desktop (Mac OS 9)'
rm -vfr /Acrobat\ Reader\ 5*
rm -vrf '/Documents'
rm -vrf '/Developer'
rm -vrf /Guides\ de\ l*
fi


echo; echo "$Icon" 'Purge Caches :' && sleep 3
sudo find /private /System /Library /Users \
\( -path "*/Caches" \
 -o -path "*/Cache" \
 -o -path "*/.cache" \
 -o -path "*/CacheTemp" \
 -o -path "*/GPUCache" \
		-o -path "*/AIMenuFaceCache" \
		-o -path "*/Office Font Cache" \
 -o -path "*/Library/Application Support/com.apple.sharedfilelist" \
 -o -path "*/Library/Application Support/CrashReporter" \
 -o -path "*/Library/Developer/Xcode/DerivedData" \
 -o -path "*/Library/Developer/Xcode/Devices" \
 -o -path "*/Library/Developer/CoreSimulator/Devices" \
 -o -path "*/Autosave Information" \
 ! -name "*finder*" \
 ! -name "*GlobalPreferences*" \) | awk '{print "sudo rm -vfr \""$0}' | awk '{print $0"/\"*"}' > /tmp/PurgeCaches.sh
sudo chmod 755 /tmp/PurgeCaches.sh && sudo /tmp/PurgeCaches.sh


echo; echo "$Icon" 'Purge Fonts Caches :' && sleep 3
sudo find /Library/Fonts/ ~/Library/Fonts/ \
\( -name "*.dir" \
 -o -name "*.scale" \
 -o -name "*.lst" \
 -o -name "*.list" \) \
 -exec rm -vrf {} \;


echo; echo "$Icon" 'Relaunch Font Server :' && sleep 3
sudo atsutil databases -remove


echo; echo "$Icon" 'Purge Deep Caches :' && sleep 3
sudo find "$TMPDIR" -type f -prune -print -delete

echo; echo "$Icon" 'Remove All Unavailable Xcode Simulators' && sleep 3
sudo xcrun simctl delete unavailable

echo; echo "$Icon" 'Purge +15 Days Logs :' && sleep 3
sudo find /var/log /Library/Logs /Users/*/Library/Logs -ctime +15 \
\( -name "*.log" \
 -o -name "*.log.*" \
 -o -name "*.crash" \
 -o -name "*.asl" \
 -o -name "*.awd" \
 -o -name "*.ips" \
 -o -name "*.bz2" \
 -o -name "*.gz" \
 -o -name "*.pklg" \
 ! -name "adam-*" \) \
 -exec rm -vrf {} \;
sudo find /private/var/log ~/Library/Logs /Library/Logs /var/log -type d -empty -delete


echo; echo "$Icon" 'Purge Tmp Prefs :' && sleep 3
sudo find /Library/Preferences /Users/*/Library/Preferences \
\( -name "*.plist.*" \
 -o -name "*-*-*-*-*.plist" \
 ! -name "*finder*" \
 ! -name "*GlobalPreferences*" \) \
-exec rm -vfr {} \;


echo; echo "$Icon" 'Purge Calendar Caches :' && sleep 3
rm -vrf /Users/*/Library/Calendars/Calendar\ Cach*


# If Terminal Is Allowed to Full Disk 10.14+
echo; echo "$Icon" 'Mail Vacuum :' && sleep 3
if test -f ~/Library/Mail/V*/MailData/Envelope\ Index ; then
if pgrep Mail ; then killall Mail || exit ; else echo Mail Not Open ; fi
sqlite3 ~/Library/Mail/V*/MailData/Envelope\ Index vacuum;
echo Mail Vacuum Done
else echo Mail Not Configured
fi


#sudo find "$HOME"/ \
#\( -name "*.plist.*" \
# -o -name ".bash_sessions" \
# -o -name ".zcompdump-*" \) \
#-exec rm -vfr {} \;


echo; echo "$Icon" 'Rebuild dyld_shared_cache :' && sleep 3
sudo rm -vrf /var/db/spindump/*
sudo update_dyld_shared_cache -force -debug -root /
#sudo update_dyld_shared_cache -root / -force


echo; echo "$Icon" 'Rebuild Open With :' && sleep 3
if [ "$OSX" -ge 7 ] ; then
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
else
sudo find /System/Library/Frameworks -type f -name "lsregister" -exec {} -kill -seed -r \;
fi


echo; echo "$Icon" 'Touch kextcache :' && sleep 3
sudo touch /System/Library/Extensions/


BootDisk=$(df -h | sed -n '2p' | cut -d' ' -f1 | cut -d'/' -f3 )
if diskutil list / | grep "$BootDisk" | grep APFS > /dev/null ; then
echo; echo "$Icon" 'Purge Old APFS Snapshot :' && sleep 3
tmutil listlocalsnapshotdates / | tail -n +2 | sed -e '$ d' | awk '{system("tmutil deletelocalsnapshots "$0)}'
tmutil thinlocalsnapshots /
fi


echo; echo "$Icon" 'Reboot in 15s…'
printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))


echo; echo "$Icon" 'Rotating Logs !'
cat < "$HOME"/Library/Logs/adam-PurgeCaches.log | gzip -9 > "$HOME"/Library/Logs/adam-PurgeCaches."$(date +"%d_%H:%M:%S")".gz
find "$HOME"/Library/Logs/adam-PurgeCaches*.gz -ctime +30 -exec rm -vfr {} \;


sleep 15 && sudo shutdown -r now adam-PurgeCaches

) 2>&1 | tee "$HOME"/Library/Logs/adam-PurgeCaches.log #Logs End
