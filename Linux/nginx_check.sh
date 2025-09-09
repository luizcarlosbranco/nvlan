#!/bin/bash
# ------------------- VARIABLES ---------------------------------------------------------------------------------
CIFSServer="YOUR_SERVER_IP"
CIFSShare="YOUR_SHARED_FOLDER"
CIFSUsername="YOUR_SERVICE_ACCOUNT@YOURDOMAIN"
CIFSPassword="YOUR_SERVICE_PASSWORD"
#----------------------------------------------------------------------------------------------------------------
ControlDate=$(date '+%Y-%m-%d %H:%M:%S')
nginx -c /etc/nginx/nginx.conf -t
CHECKNGINX=$(nginx -c /etc/nginx/nginx.conf -t 2>&1)
if [[ $CHECKNGINX == *"syntax is ok"* ]] & [[ $CHECKNGINX == *"test is successful"* ]]; then
        echo "";echo " -------------------------- Deleting all tgz files in /tmp -------------------------- ";echo""
        for oldfiles in `ls /tmp | grep $(hostname -s) | grep _ | grep tgz`; do
                rm -rf /tmp/$oldfiles
        done
        echo "";echo " -------------------------- BackUping files -------------------------- ";echo""
        file=$(hostname -s)_$(date --date="$ControlDate" '+%Y%m%d_%H%M%S').tgz
        tar cvzf /tmp/$file /etc/nginx*
        echo "";echo " -------------------------- Copying  Files to FileServer -------------------------- ";echo""
                echo "Copying $file"
                smbclient //$CIFSServer/$CIFSShare -U $CIFSUsername -pass $CIFSPassword -c "lcd /tmp/; put $file"
        echo "";echo " -------------------------- Restarting -------------------------- ";echo""
        systemctl restart nginx
fi
