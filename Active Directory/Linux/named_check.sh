#!/bin/bash
# -------------------------- Define VARIABLES --------------------------
CIFSServer="YOUR_SERVER_IP"
CIFSShare="THE_SHARE_FOLDER"
CIFSUsername="THE_SERVICE_ACCOUNT@YOURDOMAIN"
CIFSPassword="THE_SERVICE_PASSWORD"
# -------------------------- SCRIPT --------------------------
ControlDate=$(date '+%Y-%m-%d %H:%M:%S')
CurrentSOA=$(date --date="$ControlDate" '+%Y%m%d')01
echo"";echo " -------------------------- Updating Zones -------------------------- ";echo""
UpdateSerialZone () {
#       for BindZone in $(find /etc/named/zones/$1 -type f -newermt "$(cat /etc/named/zones/$1/.control.date)" | grep dns); do
        for BindZone in $(find /etc/named/zones/$1 -type f -cmin -15 | grep dns); do
                BindZoneSOA=$(grep "serial" $BindZone | head -n1 | cut -d\; -f1 | tr -d -c 0-9)
                if [[ ! -z $BindZoneSOA && ! -z $CurrentSOA ]];then
                        if [ $BindZoneSOA -ge $CurrentSOA ]; then
                                NewSOA=$(($BindZoneSOA + 1))
                        else
                                NewSOA=$CurrentSOA
                        fi
                        sed -i "s/$BindZoneSOA ; serial/"$NewSOA" ; serial/g" $BindZone
                        echo "$BindZoneSOA ---- $BindZone"
                        vairestartar=true
                fi
        done
}
UpdateSerialZone internal
UpdateSerialZone external
if [ $vairestartar ];then
        echo "";echo " -------------------------- Restarting DNS -------------------------- ";echo""
        named-checkconf
        named-checkconf -z /etc/named.conf
        systemctl restart named
        echo "Named Service ${bold}Restarted${normal}! "
fi
echo"";echo " -------------------------- BackUping files -------------------------- ";echo""
tar cvzf /tmp/$(hostname -s)_$(date --date="$ControlDate" '+%Y%m%d_%H%M%S').tgz /etc/named*
echo "";echo " -------------------------- Copying  Files to FileServer-------------------------- ";echo""
for file in `ls /tmp | grep $(hostname -s) | grep _ | grep tgz`; do
        echo "Copying $file"
        smbclient //$CIFSServer/$CIFSShare -U $CIFSUsername -pass $CIFSPassword -c "lcd /tmp/; put $file"
        rm -rf /tmp/$file
done
echo "";echo " -------------------------- Done -------------------------- ";echo""
