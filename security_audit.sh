#!/bin/bash

# Локальна папка для логів
mkdir -p logs

# Масив: VM -> користувач
declare -A users
users=(["sftp1"]="user1" ["sftp2"]="user2" ["sftp3"]="user3")

for vm in "${!users[@]}"; do
    user=${users[$vm]}
    echo "[$vm] Checking for installed rkhunter..."

    # Перевірка, чи встановлений rkhunter
    vagrant ssh "$vm" -c "command -v rkhunter >/dev/null 2>&1"
    if [ $? -ne 0 ]; then
        echo "[$vm] Installing rkhunter..."
        vagrant ssh "$vm" -c "
            sudo apk update &&
            sudo apk add bash perl curl grep e2fsprogs sysfsutils openssl-dev &&
            curl -LO https://downloads.sourceforge.net/project/rkhunter/rkhunter/1.4.6/rkhunter-1.4.6.tar.gz &&
            tar -xzf rkhunter-1.4.6.tar.gz &&
            cd rkhunter-1.4.6 &&
            sudo ./installer.sh --install &&
            rm -rf rkhunter-1.4.6 rkhunter-1.4.6.tar.gz
        "
    fi

    echo "[$vm] Running rkhunter audit..."
    vagrant ssh "$vm" -c "
        mkdir -p /tmp/rkhunter_logs &&
        sudo rkhunter --check --sk --nocolor --logfile /tmp/rkhunter_logs/${vm}_rkhunter.log &&
        sudo chmod 644 /tmp/rkhunter_logs/${vm}_rkhunter.log
    "

    echo "[$vm] Fetching logs to host machine..."
    vagrant ssh "$vm" -c "sudo cat /tmp/rkhunter_logs/${vm}_rkhunter.log" > "logs/${vm}_rkhunter.log"
    echo "[$vm] Logs saved to: logs/${vm}_rkhunter.log"
done
