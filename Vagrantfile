# -*- mode: ruby -*-
# vi: set ft=ruby :

# to make sure the pve1 node is created before the other nodes, we
# have to force a --no-parallel execution.
ENV["VAGRANT_NO_PARALLEL"] = "yes"

# require a Vagrant recent version
Vagrant.require_version ">= 2.2.0"

number_of_nodes = 2
service_network_first_node_ip = "10.10.10.2"
cluster_network_first_node_ip = "10.10.20.2"; cluster_network="10.10.20.0"
gateway_ip = "10.10.10.254"

require "ipaddr"
service_ip_addr = IPAddr.new service_network_first_node_ip
cluster_ip_addr = IPAddr.new cluster_network_first_node_ip

Vagrant.configure("2") do |config|

  # disable auto updates
  config.vm.box_check_update = false
  config.vbguest.auto_update = false

  # Configuracion do gateway
  config.vm.define "gateway" do |gw|
    # Alpine Linux box
    gw.vm.box = "boxomatic/alpine-3.16"
    gw.vm.provider "virtualbox" do |vb|
      vb.memory = 512
    end
    gw.vm.hostname = "gateway.icap.com"
    gw.vm.network "private_network", ip: gateway_ip
    gw.vm.provision "shell", path: "provision-gateway.sh", args: gateway_ip
  end

  # Configuracion dos nos
  (1..number_of_nodes).each do |n|
    name = "pve#{n}"
    fqdn = "#{name}.icap.com"
    service_ip = service_ip_addr.to_s; service_ip_addr = service_ip_addr.succ
    cluster_ip = cluster_ip_addr.to_s; cluster_ip_addr = cluster_ip_addr.succ

    config.vm.define name do |pve|

      # Box de PROXMOX
      pve.vm.box = "xoan/proxmox-ve_6.4"
      pve.vm.box_version = "1.1"
      pve.vm.hostname = fqdn

      # VirtualBox VMs con 1GB RAM e 1 CPU virtual
      pve.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 1
        vb.linked_clone = true
        vb.default_nic_type = "82540EM"
      end

      pve.vm.network "private_network", ip: service_ip, auto_config: false
      pve.vm.network "private_network", ip: cluster_ip, auto_config: false

      pve.vm.provision "shell",
        path: "provision.sh",
        args: [
          n,
          service_ip,
          cluster_network_first_node_ip,
          cluster_network,
          cluster_ip
        ]
    end
  end

end
