# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    #config.vm.box = "generic/ubuntu2204"
    config.vm.box = "ubuntu/focal64"
    #config.vm.box = "bento/ubuntu-22.04" Mais performático
    #config.vm.box = "ubuntu/jammy64"
    #config.vm.box = "debian/jessie64"  # Debian 8
    #config.vim.box = debian/bookworm64  # Debian 12
    #config.vm.box = "alvistack/ubuntu-22.04"
    config.vm.network "public_network",bridge: "Ethernet"
    config.vm.hostname = "devops-stack"
  
    config.vm.provider :virtualbox do |vb|
      vb.name = "devops-stack"
      vb.gui =  true
      vb.memory = 8192
      vb.cpus = 2
    end
    config.vm.provision "shell", path: "./provision/provision.sh"
  
  end