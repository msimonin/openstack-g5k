> This script is deprecated in favor of : https://github.com/grid5000/xp5k-openstack

# Subdirectories information

* ```juno_legacy_network``` : install ```juno``` version using a single flat network and the legacy service nova-network.
* ```juno_neutron``` : install a full SDN stack (neutron), connectivity through GRE tunnels.
Performance may be impacted (see [#8](https://github.com/msimonin/openstack-g5k/issues/8))
* ```liberty_neutron``` : install a full SDN stack (neutron), connectivity through GRE tunnels.
Performance may be impacted (see [#8](https://github.com/msimonin/openstack-g5k/issues/8))

Directory layout :
```
.
├── LICENSE
├── README.md
├── juno_legacy_network  # legacy network deployment
│   ├── grid5000            # - grid5000 deployment
│   ├── openstackg5k        # - specific puppet recipes
│   └── vagrant             # - vagrant deployment (local to your machine)
└── juno_neutron         # neutron deployment
    ├── grid5000
    ├── openstackg5k  
    └── vagrant
```

# Introduction

The deployments are based on the [puppetlabs/puppet-openstack module](https://github.com/puppetlabs/puppetlabs-openstack).

## Deploy on your local machine (```vagrant``` subdirectory - if any)

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

## Deploy on Grid'5000 (```grid'5000``` subdirectory - if any)

* ```liberty_neutron``` requires 2 network interfaces (e.g paravance / parasilo / paranoia).
* ```juno_neutron``` requires 2 network interfaces (e.g paravance / parasilo / paranoia).
* ```juno_legacy_network``` require only one network interface (thus it should be useable anywhere on grid'5000)

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

* Get or clone the repository.

```
# inside grid5000 subdirectory
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

* Get or clone the repository.

```
# inside grid5000 subdirectory
bundle install
```

* Create the ```xp.conf```file from the ```xp.conf.sample```, adapt it to your needs.


### Launch the deployment

* Launch the deployment :

```
cap automatic
```

> The above is a shortcut for cap submit deploy setup openstack

### Bootstrap the installation (if any available)
... Otherwise you'll have to create one yourself. By bootstraping I mean
creating initial networks, images ...

```
cap openstack:bootstrap
```

# Play with Openstack

## Horizon dashboard

* Make a tunnel from your local machine to the horizon dashboard

```bash
# replace <controller> and <site>
ssh -NL 8000:<controller>:80 <site>
```

* Use the VPN 

https://www.grid5000.fr/mediawiki/index.php/VPN

## From the command line 

* Make sure the proxy is unset (services API are http REST)

```bash 
# unset proxies
unset http_proxy
unset https_proxy
# access nova, neutron, keystone ... services 
```

