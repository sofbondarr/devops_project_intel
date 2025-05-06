#!/bin/bash

declare -A users
users=(["sftp1"]="user1" ["sftp2"]="user2" ["sftp3"]="user3")

for vm in "${!users[@]}"; do
    user=${users[$vm]}
    echo "[$vm] Checking for installed rkhunter..."

    vagrant ssh "$vm" -c "command -v rkhunter >/dev/null 2>&1"
    if [ $? -ne 0 ]; then
        echo "[$vm] Compiling rkhunter..."

        vagrant ssh "$vm" -c "
            sudo apk update &&
            sudo apk add bash perl curl grep e2fsprogs sysfsutils openssl-dev &&
            curl -LO https://downloads.sourceforge.net/project/rkhunter/rkhunter/1.4.6/rkhunter-1.4.6.tar.gz &&
            tar -xzf rkhunter-1.4.6.tar.gz &&
            cd rkhunter-1.4.6 &&
            sudo ./installer.sh --install &&
            rm -rf rkhunter-1.4.6 rkhunter-1.4.6.tar.gz
        "

        echo "[$vm] rkhunter installed."
    else
        echo "[$vm] rkhunter installed."
    fi

    echo "[$vm] Executing rkhunter security audit..."
    vagrant ssh "$vm" -c "
        sudo rkhunter --check --sk --nocolor --logfile /home/$user/rkhunter_report.log
    "

    echo "[$vm] Logs saved: /home/$user/rkhunter_report.log"
done
