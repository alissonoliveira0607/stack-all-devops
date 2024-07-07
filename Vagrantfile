# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    config.vm.network "public_network",bridge: "Ethernet"
    config.vm.hostname = "devops-stack"
  
    config.vm.provider :virtualbox do |vb|
      vb.name = "devops-stack"
      vb.gui =  false
      vb.memory = 8192
      vb.cpus = 2
    end
    config.vm.provision "shell", path: "./provision/provision.sh"
  
  end