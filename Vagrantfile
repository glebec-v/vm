# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.box_check_update = true
  config.vm.network "public_network", ip: "192.168.0.47"

  # config.vm.synced_folder "a", "b"

  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
     vb.memory = "1024"
    # set default network interface
     vb.customize ["modifyvm", :id, "--bridgeadapter1", "enp1s0"]
    # Customize default NAT on the VM:
     vb.customize ["modifyvm", :id, "--natnet1", "10.0.3.0/24"]
    # Customize name of the VM:
     vb.name = "otus-test"
    # Customize CPU's on the VM:
     vb.cpus = 1
  end
  
  config.vm.provision "shell" do |s|
    s.privileged = true
    s.inline = "cd /vagrant && ./install.sh"
  end
  
end
