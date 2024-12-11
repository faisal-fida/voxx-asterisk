#!/bin/zsh

chmod u+x /home/voxxverso/voxx/devops/shutdown.sh

VM_IP=$(hostname -I | cut -d' ' -f1) # Fetch local IP
SERVER_ID=$(hostname) # Fetch the hostname

cd /home/voxxverso/voxx || exit

# check
if [ -f "yes.txt" ]; then
    source .venv/bin/activate
    pip3.11 uninstall -y -r uninstall.txt
    pip3.11 install -r requirements.txt
    deactivate
else
    echo "yes.txt not found. Skipping pip operations."
fi

sudo cp -r /home/voxxverso/voxx/devops/voxx.service /etc/systemd/system/voxx.service || exit
sudo cp -r /home/voxxverso/voxx/devops/csv_updater.service /etc/systemd/system/csv_updater.service || exit
sudo cp -r /home/voxxverso/voxx/devops/csv_updater.timer /etc/systemd/system/csv_updater.timer || exit

SERVICE_FILE="/etc/systemd/system/voxx.service"

sudo sed -i "s/IP_PLACEHOLDER/$VM_IP/g" $SERVICE_FILE
sudo sed -i "s/HOSTNAME_PLACEHOLDER/$SERVER_ID/g" $SERVICE_FILE

sudo cp /home/voxxverso/voxx/devops/asterisk /etc/init.d/asterisk
sudo chown root:root /etc/init.d/asterisk
sudo chmod 755 /etc/init.d/asterisk

sudo systemctl daemon-reload

sudo systemctl restart voxx
sudo systemctl restart csv_updater.service
sudo systemctl restart csv_updater.timer

cd /home/voxxverso/voxx/logs/tmp/ || exit

sudo rm -rf *

cd /home/voxxverso/voxx/src/data/asterisk/dec/ || exit

sudo rm -rf *

cd /home/voxxverso/voxx/src/data/asterisk/recordings/ || exit

sudo rm -rf *

cd /home/voxxverso/voxx/src/data/asterisk/ || exit

sudo rm -rf *.txt

cd ~ || exit

sudo cp -r /home/voxxverso/voxx/devops/config/asterisk_conf/* /etc/asterisk/ || exit

# DD: Used again
VM_IP=$(hostname -I | cut -d' ' -f1)

EXTERNAL_IP=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google")

sudo sed -i "s/EXTERNAL_IP/$EXTERNAL_IP/g" /etc/asterisk/pjsip.conf
sudo sed -i "s/IP_PLACEHOLDER/$VM_IP/g" /etc/asterisk/extensions.conf

sudo /usr/sbin/asterisk -rx "core reload"
sudo /usr/sbin/asterisk -rx "dialplan reload"
sudo /usr/sbin/asterisk -rx "module reload res_pjsip.so"

sudo cp -r /home/voxxverso/voxx/devops/config/config.yaml /etc/google-cloud-ops-agent/config.yaml || exit

sudo systemctl stop asterisk

sleep 2

sudo systemctl start asterisk

sudo systemctl restart google-cloud-ops-agent