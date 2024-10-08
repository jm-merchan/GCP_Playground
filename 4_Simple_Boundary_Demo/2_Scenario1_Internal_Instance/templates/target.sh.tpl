#!/usr/bin/env bash
echo "${ca_pub}" > /etc/ssh/ca-key.pub
sudo chown 1000:1000 /etc/ssh/ca-key.pub
sudo chmod 644 /etc/ssh/ca-key.pub
sudo echo TrustedUserCAKeys /etc/ssh/ca-key.pub >> /etc/ssh/sshd_config
sudo echo PermitTTY yes >> /etc/ssh/sshd_config
sudo sed -i 's/X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
sudo echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
sudo systemctl restart sshd

curl 'https://api.ipify.org?format=txt' > /tmp/ip
cat /tmp/ip