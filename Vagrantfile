Vagrant.configure("2") do |config|
    machines = {
      "sftp1" => { ip: "192.168.56.11", user: "user1" },
      "sftp2" => { ip: "192.168.56.12", user: "user2" },
      "sftp3" => { ip: "192.168.56.13", user: "user3" }
    }
  
    machines.each do |name, data|
      config.vm.define name do |vm|
        vm.vm.box = "generic/alpine318"
        vm.vm.hostname = name
        vm.vm.network "private_network", ip: data[:ip]
        vm.vm.provider "virtualbox" do |vb|
          vb.memory = 256
          vb.cpus = 1
        end
        vm.vm.provision "shell", inline: <<-SHELL
          apk update
          apk add openssh sudo bash
          adduser -D #{data[:user]}
          echo '#{data[:user]} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
          echo '#{data[:user]}:#{data[:user]}' | chpasswd
          mkdir -p /home/#{data[:user]}/.ssh
          chown -R #{data[:user]}:#{data[:user]} /home/#{data[:user]}/.ssh
          chmod 700 /home/#{data[:user]}/.ssh
          rc-update add sshd
          service sshd start
        SHELL
      end
    end
  end
  