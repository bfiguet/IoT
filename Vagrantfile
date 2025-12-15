Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
  end

  config.vm.define "vm-p3" do |node|
    node.vm.network "private_network", ip: "192.168.56.120"
    node.vm.hostname = "vm-p3"

    node.vm.provider "virtualbox" do |vb|
      vb.name = "v"
      vb.cpus = 2
      vb.memory = "2048"
    end

    node.vm.provision "base", type: "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y curl wget git htop
    SHELL
  end
end
