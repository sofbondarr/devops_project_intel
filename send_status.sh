#!/bin/bash

SELF=$(hostname)
NOW=$(date "+%Y-%m-%d %H:%M:%S")
MESSAGE="[$SELF] $NOW → Hello from $SELF"

# Визначаємо сусідів
declare -A HOSTS
HOSTS=(
  ["sftp1"]="192.168.56.11"
  ["sftp2"]="192.168.56.12"
  ["sftp3"]="192.168.56.13"
)

for HOSTNAME in "${!HOSTS[@]}"; do
    HOST_IP=${HOSTS[$HOSTNAME]}

    # не надсилаємо самі собі
    if [[ "$HOSTNAME" != "$SELF" ]]; then
        echo "[$SELF] Sending log entry to $HOSTNAME ($HOST_IP)"
        ssh -o StrictHostKeyChecking=no user@${HOST_IP} "echo '$MESSAGE' >> /home/user/incoming/status.log"
    fi
done
