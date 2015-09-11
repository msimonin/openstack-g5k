*Work in progress*

Master branch tracks *juno* version.


# Introduction

The project aims to deploy openstack either on 

* your local machine (using vagrant)
* on Grid'5000

It is based on the [puppetlabs/puppet-openstack module](https://github.com/puppetlabs/puppetlabs-openstack).

Once ready, this script will deprecate https://github.com/capi5k/capi5k-openstack which was based on the Icehouse version of Openstack and using the legacy nova-network and a single flat network.

## Deploy on your local machine

### Requirements

* r10k gem, to install all the module dependencies (```gem install r10k```)
* [vagrant](http://www.vagrantup.com/downloads.html)
* the [```hostmanager```](https://github.com/smdahlen/vagrant-hostmanager) plugin for vagrant

### Deploy

Tested on (feel free to add your own configuration)
* MacOsX / Virtualbox 4.3.10 / Vagrant 1.7.2 

Just launch : 
```
$) ./deploy.sh
```

### Tests

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

For the moment you'll have to use nodes with 2 network interfaces (e.g paravance / parasilo / paranoia).
See [#12](https://github.com/msimonin/openstack-g5k/issues/12).

### From inside Grid'5000

* Connect to the frontend of your choice

* Configure [restfully](https://github.com/crohr/restfully)

```
mkdir ~/.restfully
echo "base_uri: https://api.grid5000.fr/3.0/" > ~/.restfully/api.grid5000.fr.yml
```

* Enable proxy

```
export http_proxy=http://proxy:3128
export https_proxy=http://proxy:3128
```

* Install bundler and make ruby executables available

```
gem install bundler --user
export PATH=$PATH:$HOME/.gem/ruby/1.9.1/bin
```

* Clone the repository.

```
cd openstack-g5k
bundle install --path ~/.gem
```

* Create the ```xp.conf```file from the ```xp.conf.sample```, adapt it to your needs.

> Comment the ```gateway``` line

### From oustside Grid'5000

* Configure  [restfully](https://github.com/crohr/restfully)

```
echo '
uri: https://api.grid5000.fr/3.0/
username: MYLOGIN
password: MYPASSWORD
' > ~/.restfully/api.grid5000.fr.yml && chmod 600 ~/.restfully/api.grid5000.fr.yml
```

* (optional but highly recommended) Install [rvm](http://rvm.io)

* Clone the repository.

```
cd openstack-g5k
bundle install --path ~/.gem
```

* Create the ```xp.conf```file from the ```xp.conf.sample```, adapt it to your needs.


### Configure and launch the deployment

* Launch the deployment :

```
cap automatic
```

> The above is a shortcut for cap submit deploy setup openstack
