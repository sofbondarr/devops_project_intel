#!/bin/bash

declare -A users
users=(["sftp1"]="user1" ["sftp2"]="user2" ["sftp3"]="user3")

echo "Setting up SSH ..."

for vm in "${!users[@]}"; do
    user=${users[$vm]}
    echo "Generation key $vm for $user"
    vagrant ssh "$vm" -c "
        sudo -u $user ssh-keygen -t ed25519 -f /home/$user/.ssh/id_ed25519 -N '' <<< y
        sudo chown $user:$user /home/$user/.ssh/id_ed25519
        sudo chmod 600 /home/$user/.ssh/id_ed25519
    "
done

declare -A pubkeys
for vm in "${!users[@]}"; do
    user=${users[$vm]}
    echo "Getting public key from $vm"
    pubkeys[$vm]=$(vagrant ssh "$vm" -c "sudo cat /home/$user/.ssh/id_ed25519.pub" | tr -d '\r')
done

for target_vm in "${!users[@]}"; do
    target_user=${users[$target_vm]}
    echo "Setting up $target_vm ($target_user)"
    vagrant ssh "$target_vm" -c "
        sudo rm -f /home/$target_user/.ssh/authorized_keys
    "
    for source_vm in "${!users[@]}"; do
        if [ "$target_vm" != "$source_vm" ]; then
            key="${pubkeys[$source_vm]}"
            vagrant ssh "$target_vm" -c "
                echo '$key' | sudo tee -a /home/$target_user/.ssh/authorized_keys > /dev/null
                sudo chown $target_user:$target_user /home/$target_user/.ssh/authorized_keys
                sudo chmod 600 /home/$target_user/.ssh/authorized_keys
            "
        fi
    done
done

echo "Keys setup Seccessful"
