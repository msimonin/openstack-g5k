require 'netaddr'
require 'ipaddr'
require 'hiera'
require 'yaml'

set :openstack_path, "."

load "#{openstack_path}/roles.rb"
load "#{openstack_path}/output.rb"

set :user, "root"

def clean(s) 
  return s.gsub("\n", "")
end


# return the hash map credentials
def rc(name)
  config = YAML::load_file("#{openstack_path}/puppet/hiera/common.yaml")
  user = config["openstack::keystone::users"][name]
  if (user.nil?)
    return {}
  end

  return {
    "OS_USERNAME"            => name,
    "OS_PASSWORD"            => user["password"],
    "OS_TENANT_NAME"         => user["tenant"],
    'OS_AUTH_URL'            => 'http://localhost:5000/v2.0/',
    'OS_REGION_NAME'         => 'openstack',
    'KEYSTONE_ENDPOINT_TYPE' => 'publicURL',
    'NOVA_ENDPOINT_TYPE'     => 'publicURL'
  }
end

def proxy 
  return {
    "http_proxy" => "http://proxy:3128",
    "https_proxy" => "http://proxy:3128",
    "no_proxy" => "localhost,127.0.0.0/8,127.0.1.1,127.0.1.1*,local.home"
  }
end
def noproxy 
  return {
    "http_proxy" => "",
    "https_proxy" => "",
  }
end

task :automatic do
  puts "Openstack deployment"
end


namespace :setup do

  desc 'Setup a puppet cluster on nodes and configure vlan'
  task :default do 
    puppet::default
    vlan::default
  end

  namespace :puppet do
    task :default do
      setup_master
      setup_agents
      fix
      ip
      generate
      transfer
      install
      certs_request
    end

    task :setup_master, :roles => [:puppet_master] do
    set :user, "root"
      run "apt-get update || true"
      run "wget  https://apt.puppetlabs.com/puppetlabs-release-trusty.deb"
      run "dpkg -i puppetlabs-release-trusty.deb"
      run "apt-get update || true"
      run "apt-get -y install --force-yes puppetmaster-common=3.6.1-1puppetlabs1 puppet-common=3.6.1-1puppetlabs1 puppet=3.6.1-1puppetlabs1 puppetmaster-passenger=3.6.1-1puppetlabs1"
    end

    task :setup_agents, :roles => [:puppet_clients] do
      set :user, "root"
      run "apt-get update || true"
      run "wget  https://apt.puppetlabs.com/puppetlabs-release-trusty.deb"
      run "dpkg -i puppetlabs-release-trusty.deb"
      run "apt-get update || true"
      run "apt-get -y install --force-yes puppet-common=3.6.1-1puppetlabs1 puppet=3.6.1-1puppetlabs1"
      run "puppet agent --enable"
    end

    task :fix, :roles => [:puppet_master] do
      run "rm -rf /var/lib/puppet/yaml"
    end

    task :ip, :roles => [:puppet_master] do
      set :user, "root"
      ip = capture("facter ipaddress")
      File.write("tmp/ipmaster", ip)
    end

    task :generate do
      agents = find_servers :roles => [:puppet_clients]
      @agents = agents.map{|a| a.host}
      template = File.read("templates/autosign.conf.erb")
      renderer = ERB.new(template, nil, '-<>')
      generate = renderer.result(binding)
      myFile = File.open("tmp/autosign.conf", "w")
      myFile.write(generate)
      myFile.close
    end

    task :transfer, :roles => [:puppet_master] do
      set :user, "root"
      upload "tmp/autosign.conf", "/etc/puppet/autosign.conf", :via => :scp
      run "service apache2 restart"
    end

    task :install, :roles => [:puppet_clients] do
      set :user, "root"
      # pupet has been installed before
      ipmaster = File.read("tmp/ipmaster").delete("\n")
      run "echo '\n #{ipmaster} puppet' >> /etc/hosts"
    end

    task :certs_request, :roles => [:puppet_clients] do
      set :user, "root"
      run "puppet agent -t"
    end

    task :certs_sign, :roles => [:puppet_master] do
      set :user, "root"
      run "puppet certs sign --all"
    end

  end # puppet

  namespace :vlan do 

    desc 'Puts the interface in the vlan'
    task :default do
      set
      dhcp
    end

    task :set do
      vlanid = $myxp.job_with_name("#{XP5K::Config['jobname']}")['resources_by_type']['vlans'].first.to_i
      nodes = find_servers :roles => [:controller, :network, :compute]
      nodes = nodes.map{|n| n.to_s.gsub(/-(\d+)/, '-\1-' + XP5K::Config['management_interface'])}
      logger.info "Setting in vlan #{vlanid} following nodes : #{nodes.inspect}"
      root = $myxp.connection.root.sites[XP5K::Config['site'].to_sym]
      vlan = root.vlans.find { |item| item['uid'] == vlanid.to_s }
      vlan.submit :nodes => nodes
    end

    task :dhcp, :roles => [:controller, :network, :compute] do
      run "dhclient -nw eth1"
    end

 end # vlan

end

namespace :openstack do
  
  desc 'Deploy openstack on the nodes (puppet / vlan already configured)'
  task :default do
    mod::default
    hiera::default
    sitepp::default
    run_agents::default
  end


  namespace :mod do
    desc 'Install all the necessary for the puppet module'
    task :default do
      prepare
      install
    end

    task :prepare, :roles => [:puppet_master] do
      set :user, "root"
      run "rm -rf /etc/puppet/modules"
      # fix an issue with wrong dependency
      upload "#{openstack_path}/puppet/Puppetfile", "/etc/puppet/Puppetfile", :via => :scp
      upload "#{openstack_path}/puppet/hiera.yaml", "/etc/puppet/hiera.yaml", :via => :scp
    end 

    task :install, :roles => [:puppet_master] do
      set :user, "root"
      set :default_environment, proxy
      run "apt-get install -y git"
      run "gem install r10k --no-ri --no-rdoc"
      run "cd /etc/puppet && r10k -v info puppetfile install"
      upload "#{openstack_path}/../openstackg5k", "/etc/puppet/modules", :via => :scp, :recursive => :true
    end
  end

  namespace :hiera do
    
    desc 'Install the hiera database'
    task :default do
      subnet
      template
      install
    end

    task :subnet  do
        frontend = (find_servers :roles => [:frontend]).first
        jobid = $myxp.job_with_name("#{XP5K::Config['jobname']}")['uid']
        subnet = (capture "g5k-subnets -j #{jobid} -a", :hosts => frontend).split("\t")
        # output example : 
        #     0                1             2            3              4                5                     6
        # 10.158.4.0/22  10.159.255.255  255.252.0.0 10.159.255.254  10.156.0.0  dns.rennes.grid5000.fr  172.16.111.118
        cidr =  NetAddr::CIDR.create(subnet[0])
        # we use the glbal /14 network provided by g5K,
        # we just make sure to assign ip in the right range.
        @externalNetwork =  "#{subnet[4]}/14"
        @gateway = subnet[3]
        @dns=subnet[-1]
        @ipstart = cidr.first
        @ipend = cidr.last
        puts "First IP: " + @ipstart
        puts "Last IP : " + @ipend
        puts "gateway : " + @gateway
        puts "DNS     : " + @dns
    end
    task :template do
      set :user, "root"
      # get controller address
      controller = (find_servers :roles => [:controller]).first
      apiNet = clean(capture "facter network_eth0", :hosts => controller)
      apiNetmask = clean(capture "facter netmask_eth0", :hosts => controller)
      # compute the cidr notation (add a custom fact ?)
      apiCidr = IPAddr.new(apiNetmask).to_i.to_s(2).count("1")
      managementNet = clean(capture "facter network_eth1", :hosts => controller)
      managementNetmask = clean(capture "facter netmask_eth1", :hosts => controller)
      managementCidr = IPAddr.new(managementNetmask).to_i.to_s(2).count("1")
      @apiNetwork = "#{apiNet}/#{apiCidr}"
      @managementNetwork = "#{managementNet}/#{managementCidr}"
      @dataNetwork = @managementNetwork
      @controllerAddressApi = capture "facter ipaddress_eth0", :hosts => controller
      @controllerAddressManagement = capture "facter ipaddress_eth1", :hosts => controller
      @controllerAddressManagement = @controllerAddressManagement.gsub("\n", "")
      @controllerAddressApi = @controllerAddressApi.gsub("\n", "")
      @allowedHost = @controllerAddressManagement.gsub(/(\d)+\.(\d)+$/, "%.%")

      # storage on the control node.
      storage = (find_servers :roles => [:controller]).first
      @storageAddressApi = capture "facter ipaddress_eth0", :hosts => storage
      @storageAddressManagement = capture "facter ipaddress_eth1", :hosts => storage
      @storageAddressManagement = @storageAddressManagement.gsub("\n", "")
      @storageAddressApi = @storageAddressApi.gsub("\n", "")

      template = File.read("#{openstack_path}/templates/common.yaml.erb")
      renderer = ERB.new(template)
      generate = renderer.result(binding)
      myFile = File.open("#{openstack_path}/puppet/hiera/common.yaml", "w")
      myFile.write(generate)
      myFile.close

    end

    task :install, :roles => [:puppet_master] do
      set :user, "root"
      upload("#{openstack_path}/puppet/hiera","/etc/puppet", :via => :scp, :recursive => true)
    end

    task :uninstall, :roles => [:puppet_master] do
      set :user, "root"
      run "rm -rf /etc/puppet/hiera"
    end 
  end # hiera

  namespace :sitepp do
    # Matt : replace the generation with a template (more flexible)
    desc 'Generate and upload the site.pp'
    task :default do
      generate
      transfer
    end

    task :generate do
      controller = find_servers :roles => [:controller]
      manifest = %{
node '#{controller.first.host}' {
  include openstackg5k::role::controller
}
      }
      compute = find_servers :roles => [:compute]
      compute.each do |c|
        manifest << %{
node '#{c}' {
  class{'::openstack::role::compute':}
}
      }
      end
      network = find_servers :roles => [:network]
      network.each do |n|
        manifest << %{
node '#{n}' {
  class{'::openstackg5k::role::network':}
}
        }
      end
      File.write('tmp/site.pp', manifest)
    end

    task :transfer, :roles => [:puppet_master] do
      set :user, 'root'
      upload "#{openstack_path}/tmp/site.pp", "/etc/puppet/manifests/", :via => :scp
    end

  end # sitepp

  task :fix_permissions, :roles => [:puppet_master] do
    set :user, "root"
    run "chmod 755 -R /etc/puppet"
  end


  namespace :run_agents do
    
    desc "Launch puppet runs on nodes"
    task :default do
      controller
      network
      compute
    end

    desc 'Provision the controller'
    task :controller, :roles => [:controller] do
      set :default_environment, proxy
      # it seems that using, :on_error => :continue fails on the following tasks
      # no server for ... we force to true
      run "puppet agent -t || true"
    end

    desc 'Provision the other nodes'
    task :network, :roles => [:network] do
      set :default_environment, noproxy
      # force the creation of the bridge
      run "apt-get install -y openvswitch-switch"
      run "ovs-vsctl add-br brex && ovs-vsctl add-port brex eth0 && ifconfig eth0 0.0.0.0 && dhclient -nw brex"
      run "puppet agent -t || true"
    end

    desc 'Provision the other nodes'
    task :compute, :roles => [:compute] do
      set :default_environment, noproxy
      # force the creation of the bridge
      run "puppet agent -t || true"
    end
  
  end

  namespace :bootstrap do
    desc 'Bootstrap the environment (add image/sec-group/network)' 
    task :default do
      upload_keys
      images
      network
      testrc
      admin_ec2
      quotas
      demo::default
      ec2_boot
      nova_boot
    end

    task :upload_keys, :roles => [:controller] do
      set :user, "root"
      run "rm -f /root/.ssh/id_rsa*"
      run 'ssh-keygen -f /root/.ssh/id_rsa -N ""'
      run "chmod 600 -R /root/.ssh"
    end

    task :images, :roles => [:controller] do
      set :default_environment, rc('test')
      set :user, "root"
       XP5K::Config[:images].each do |image|
        run "wget -q #{image[:url]} -O #{image[:name]}"
        run "glance add name='#{image[:name]}' is_public=true container_format=ovf disk_format=qcow2 < #{image[:name]}"
        run "nova image-list"
      end
    end

    task :network, :roles => [:controller] do
      set :default_environment, rc('test')
      set :user, "root"
      controllerAddress = capture "facter ipaddress"

      # get vlan number using the jobname variable
      vlan = $myxp.job_with_name("#{XP5K::Config[:jobname]}")['resources_by_type']['vlans'].first.to_i
      # get corresponding IP and add 30 to the c part to not collide with any host of g5k
      vlan_config = YAML::load_file("#{openstack_path}/config/vlan-config.yaml")
      ip=vlan_config["#{XP5K::Config[:site]}"][vlan]
      cidr =  NetAddr::CIDR.create(ip)
      splited_ip = cidr.first.split('.')
      c=(splited_ip[2].to_i+30).to_s

      # we choose a range of ips which doen't collide with any host of g5k 
      # see https://www.grid5000.fr/mediawiki/index.php/User:Lnussbaum/Network#KaVLAN
      # here 255 hosts only
      nova_net = controllerAddress.gsub(/(\d)+\.(\d)+$/, c+".0/24")
      run "nova network-create net-jdoe --bridge br100 --multi-host T --fixed-range-v4 #{nova_net}"
      run "nova net-list"
    end
    
    task :testrc, :roles => [:controller] do
      set :user, "root"
      rc = rc("test")
      run "echo \"\" > testrc" 
      rc.each do |k,v| 
        run "echo \"export #{k}=#{v}\" >> testrc"
      end
    end

    task :admin_ec2, :roles => [:controller] do
      set :default_environment, rc('test')
      set :user, "root"
      # acces and secret key
      run "keystone ec2-credentials-create > admin.ec2"
      run "cat admin.ec2"
    end

    task :quotas, :roles => [:controller], :on_error => :continue do
      set :default_environment, rc('test')
      set :user, "root"
      # disable quotas
      run "nova quota-class-update --cores -1 default"
      run "nova quota-class-update --instances -1 default"
      run "nova quota-class-update --ram -1 default"
      # run some checks
      run "nova-manage service list | sort"
      puts "### Now creating EC2 credentials"
    end

    namespace :demo do

      desc 'Bootstrap the demo user'
      task :default do
        demorc
        keypair
        sec_group
        ec2 
      end

      task :demorc, :roles => [:controller] do
        set :user, "root"
        rc = rc("demo")
        run "echo \"\" > demorc" 
        rc.each do |k,v| 
          run "echo \"export #{k}=#{v}\" >> demorc"
        end
      end

      task :keypair, :roles => [:controller] do
        set :user, "root"
        set :default_environment, rc('demo')
        run "nova keypair-add --pub_key /root/.ssh/id_rsa.pub jdoe_key"
      end

      # we allow all traffic on the default sec group as well
      task :sec_group, :roles => [:controller] do
        set :user, "root"
        set :default_environment, rc('demo')
        run "nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0"
        run "nova secgroup-add-rule default udp 1 65535 0.0.0.0/0"
        run "nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0"
        run "nova secgroup-list-rules default"
        run "nova secgroup-create vm_jdoe_sec_group 'vm_jdoe_sec_group test security group'"
        run "nova secgroup-add-rule vm_jdoe_sec_group tcp 1 65535 0.0.0.0/0"
        run "nova secgroup-add-rule vm_jdoe_sec_group udp 1 65535 0.0.0.0/0"
        run "nova secgroup-add-rule vm_jdoe_sec_group icmp -1 -1 0.0.0.0/0"
        run "nova secgroup-list-rules vm_jdoe_sec_group"
      end

      task :ec2, :roles => [:controller] do
        set :user, "root"
        set :default_environment, rc('demo')
        run "keystone ec2-credentials-create > demo.ec2"
        run "cat demo.ec2"
      end

    end

    task :ec2_boot, :roles => [:controller] do
      set :user, "root"
      run "cat admin.ec2"
      puts "You can run instances using ec2 : "
      puts "EC2_ACCCESS_KEY=abc EC2_SECRET_KEY=abc EC2_URL=abc euca-run-instances -n 1 -g vm_jdoe_sec_group -k jdoe_key -t m1.medium ubuntu-image"
    end


    desc 'reminder about booting a VMs'
    task :nova_boot do
      puts "You are now ready to boot a VM as demo user: (change the net-id) "
      puts "nova boot --flavor 3 --security_groups vm_jdoe_sec_group --image ubuntu-13.10 --nic net-id=a665bfd4-53da-41a8-9bd6-bab03c09b890 --key_name jdoe_key  ubuntu-vm"
    end

  end
end
