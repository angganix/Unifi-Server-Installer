#!/bin/bash

# Update and upgrade the system
apt update -y

# Install additional basic dependencies
apt install -y ca-certificates apt-transport-https curl gnupg lsb-release libc-bin dpkg

# Add directories containing ldconfig and start-stop-daemon to PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin:/bin

# Check if ldconfig and start-stop-daemon exist, if not install missing utilities
if ! command -v ldconfig &> /dev/null; then
    echo "ldconfig not found, installing libc-bin."
    apt install -y libc-bin
fi

if ! command -v start-stop-daemon &> /dev/null; then
    echo "start-stop-daemon not found, installing dpkg."
    apt install -y dpkg
fi

# Add backports repository to get libssl1.1
echo "deb http://deb.debian.org/debian bullseye main" | tee /etc/apt/sources.list.d/bullseye.list
apt update

# Install libssl1.1 from Debian 11 (Bullseye)
apt install -y libssl1.1

# Remove the backports repository after installing libssl1.1 to avoid issues
rm /etc/apt/sources.list.d/bullseye.list
apt update

# Add MongoDB 4.4 repository
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-4.4.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

# Install MongoDB 4.4
apt update
apt install -y mongodb-org

# Start and enable MongoDB
systemctl start mongod
systemctl enable mongod

# Check MongoDB status
if systemctl is-active --quiet mongod; then
    echo "MongoDB service is active and running."
else
    echo "MongoDB service is not running. Please check the logs for more details."
    exit 1
fi

# Add directory to PATH
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin

# Download and install UniFi Controller 7.5 from provided URL
wget https://dl.ubnt.com/unifi/8.4.59/unifi_sysvinit_all.deb -O /tmp/unifi_sysvinit_all.deb
dpkg -i /tmp/unifi_sysvinit_all.deb

# Fix broken dependencies if any
apt --fix-broken install -y

# Check if UniFi Controller is installed correctly
dpkg -l | grep unifi
if [ $? -ne 0 ]; then
    echo "UniFi Controller is not installed correctly. Check the installation logs for more details."
    exit 1
fi

# Start and enable UniFi Controller
systemctl start unifi
systemctl enable unifi

# Check UniFi Controller status
if systemctl is-active --quiet unifi; then
    echo "UniFi Controller service is active and running."
else
    echo "UniFi Controller service is not running. Please check the logs for more details."
    exit 1
fi

# Show UniFi Controller status
systemctl status unifi

# Finished
echo "UniFi Controller and MongoDB 4.4 setup is complete. Access the UniFi Controller at https://<YOUR-IP>:8443"