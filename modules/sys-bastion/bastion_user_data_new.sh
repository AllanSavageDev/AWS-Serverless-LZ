#!/bin/bash
set -eux

# --- Enable IP forwarding persistently ---
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-nat.conf
sysctl -p /etc/sysctl.d/99-nat.conf

# --- Install iptables and configure NAT masquerade ---
yum install -y -q iptables-services

# Flush any existing rules and apply masquerade
iptables -t nat -F
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save rules persistently
service iptables save
systemctl enable iptables
systemctl start iptables

# --- Ensure rules are restored at boot ---
cat >/etc/systemd/system/nat-restore.service <<'SERVICE'
[Unit]
Description=Restore NAT configuration
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/sysconfig/iptables
ExecStartPost=/usr/sbin/sysctl -w net.ipv4.ip_forward=1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable nat-restore.service
systemctl start nat-restore.service

echo "NAT ready" > /var/log/nat-ready.log




# --- Build Box Tooling -------------------------------------------------------

# Install git
yum install -y git

# Install AWS CLI v2
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Install Terraform
T_VERSION="1.9.5"
curl -s -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${T_VERSION}/terraform_${T_VERSION}_linux_amd64.zip
unzip -q /tmp/terraform.zip -d /usr/local/bin
chmod +x /usr/local/bin/terraform

# Install Python3 + pip
#yum install -y python3 python3-pip

# amazon-linux-extras install epel -y
# yum install -y python3.12 python3.12-devel
# alternatives --set python3 /usr/bin/python3.12
# alternatives --set pip3 /usr/bin/pip3.12


# Create build working directory
mkdir -p /opt/buildbox
chmod 755 /opt/buildbox

echo "Build box ready" > /var/log/build-ready.log

# Install boto3 for Python automation
pip3 install boto3


