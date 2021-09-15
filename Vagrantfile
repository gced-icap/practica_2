# to make sure the pve1 node is created before the other nodes, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

number_of_nodes = 2
service_network_first_node_ip = '10.10.10.2'
cluster_network_first_node_ip = '10.10.20.2'; cluster_network='10.10.20.0'
gateway_ip = '10.10.10.254'

require 'ipaddr'
service_ip_addr = IPAddr.new service_network_first_node_ip
cluster_ip_addr = IPAddr.new cluster_network_first_node_ip

Vagrant.configure('2') do |config|

  # Configuración do gateway
  config.vm.define 'gateway' do |config|
    config.vm.box = 'hashicorp/bionic64'
    config.vm.provider :virtualbox do |vb|
      vb.memory = 512
    end
    config.vm.hostname = 'gateway.icap.com'
    config.vm.network :private_network, ip: gateway_ip, nic_type: "virtio"
    config.vm.provision :shell, path: 'provision-gateway.sh', args: gateway_ip
  end

  # Configuración dos nós
  (1..number_of_nodes).each do |n|
    name = "pve#{n}"
    fqdn = "#{name}.icap.com"
    service_ip = service_ip_addr.to_s; service_ip_addr = service_ip_addr.succ
    cluster_ip = cluster_ip_addr.to_s; cluster_ip_addr = cluster_ip_addr.succ

    config.vm.define name do |config|
      # PROXMOX box
      config.vm.box = 'xoan/proxmox-ve_6.4'
      config.vm.box_version = '1.0'
      config.vm.hostname = fqdn

      # VirtualBox VMs con 1GB RAM e 1 CPU virtual
      config.vm.provider :virtualbox do |vb|
        vb.linked_clone = true
        vb.memory = 1024
        vb.cpus = 1
      end

      config.vm.network :private_network, ip: service_ip, auto_config: false, nic_type: "virtio"
      config.vm.network :private_network, ip: cluster_ip, auto_config: false, nic_type: "virtio"

      config.vm.provision :shell,
        path: 'provision.sh',
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
