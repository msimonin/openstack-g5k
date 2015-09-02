*Work in progress*

# Introduction

We aim to provide methods to deploy Openstack on your local machine (using Vagrant) and on Grid'5000.
We sit on top of the following puppet module : https://github.com/puppetlabs/puppetlabs-openstack

## Deploy on your local machine

### Requirements

* r10k gem, to install all the module dependencies (```gem install r10k```)
* vagrant, [download it](http://www.vagrantup.com/downloads.html)
* the [```hostmanager```](https://github.com/smdahlen/vagrant-hostmanager) plugin for vagrant

### Deploy

Tested on 
* MacOsX / Virtualbox 4.3.10 / Vagrant 1.7.2 

Just launch : 
```
$) ./deploy.sh
```

After the deployment some manual steps are still required. Of course they need to be integrated in the automatic deployer.
Feel free to code them and send a pull request :

- [ ] sets qemu as virtualization technology on the compute node (edit ```/etc/nova/nova.conf``` and ```/etc/nova/nova-compute.conf```)
- [ ] restart neutron-server on the controller node (something is wrong with tenant network otherwise)



### (minimal) notes and known issues

* [test] network connectivity

The ip of the external gateway should be pingable from anywhere.
If not check the ```brex```bridge on the network node :
```
$)root@network:~# ovs-vsctl list-ports brex
eth2
qg-0ccc561c-4c
```

N.B: The eth2 corresponding virtual box interface is configured to be in ```promisc``` mode (check the virtual box gui). This is setup in the Vagrantfile.

* [test] floating ip
 Floating ips should be pingable and sshable from anywhere.

* [issue] floating ip association
seems to not work with the predefined private network, create another one seems to fix the issue.

## Deploy on Grid'5000
