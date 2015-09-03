capi5k-openstack
=================

### Summary

  * [Overview](#overview)
  * [Deploy](#deploy)
    * [From inside Grid'5000](from-inside-grid'5000)
    * [From outside Grid'5000](from-outside-grid'5000)
    * [Check the deployment](check-the-deployment)
  * [Boot VMs](#boot-vms)
    * [Using Nova](#using-nova)
    * [Using EC2](#using-ec2)
    * [Using the web interface](#using-the-web-interface)
  * [Miscellaneous](#miscellaneous)
    * [Setting a cron job](#setting-a-cron-job)

## Overview

* Base image : ubuntu1204
* Openstack Icehouse
* Legacy network configured to be high available (one nova-network / compute node)
* Nodes are put in a local routed VLAN.

Openstack is bootstraped with the following:

* Some base images (see ```xp.conf```)

```
nova image-list
+--------------------------------------+--------------+--------+--------+
| ID                                   | Name         | Status | Server |
+--------------------------------------+--------------+--------+--------+
| ec350d7b-e075-4725-baa0-42fc547a277b | ubuntu-13.10 | ACTIVE |        |
+--------------------------------------+--------------+--------+--------+

```

* One network ```/24``` used for the VMs IPs (automatically generated from the vlan network)

```
nova net-list
+--------------------------------------+----------+----------------+
| ID                                   | Label    | CIDR           |
+--------------------------------------+----------+----------------+
| 8462e71b-81ce-4d0f-8bfd-10f8bb73b29c | net-jdoe | 10.27.230.0/24 |
+--------------------------------------+----------+----------------+
```

* 2 specific users (see ```common.yml.erb```)
  * demo is in the demo tenant
  * test has admin permissions.

```
keystone user-list
+----------------------------------+------------+---------+---------------------------+
|                id                |    name    | enabled |           email           |
+----------------------------------+------------+---------+---------------------------+
| 59fc0746333b47eab928bc05dcc5b576 |    demo    |   True  |      demo@example.com     |
| ac5d82e9217c42e3af2e51466ecbf2c7 |    test    |   True  |      test@example.com     |
...
+----------------------------------+------------+---------+---------------------------+
```
* Some files generated on the controller

```
$ ls -l
total 242380
-rw-r--r-- 1 root root       441 Nov 17 17:02 admin.ec2 # user test EC2 credentials
-rw-r--r-- 1 root root       441 Nov 17 17:02 demo.ec2  # user demo EC2 credentials
-rw-r--r-- 1 root root       233 Nov 17 17:02 demorc    # user demo internal API exports
-rwx------ 1 root root       446 Nov 17 16:29 openrc    # user admin internal API exports
...
```

## Deploy


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

* Download the latest bundle release tarball (```capi5k-openstack-x.y.z-bundle.tar.gz```)
from the [releases page](https://github.com/capi5k/capi5k-openstack/releases).

```
cd capi5k-openstack*
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

* Download the latest bundle release tarball (```capi5k-openstack-x.y.z-bundle.tar.gz```)
from the [releases page](https://github.com/capi5k/capi5k-openstack/releases).

```
cd capi5k-openstack*
bundle install --path ~/.gem
```

* Create the ```xp.conf```file from the ```xp.conf.sample```, adapt it to your needs.


### Configure and launch the deployment

* Launch the deployment :

```
cap automatic
```

> The above is a shortcut for cap submit deploy puppetcluster openstack openstack:bootstrap

### Check the deployment

* ```cap describe```

```
+----------------------------------------------------------------------+
|puppet_master                 parapluie-31-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|puppet_clients                parapluie-8-kavlan-16.rennes.grid5000.fr|
|                              parapluie-32-kavlan-16.rennes.grid5000.fr|
|                              parapluie-35-kavlan-16.rennes.grid5000.fr|
|                              parapluie-38-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|controller                    parapluie-32-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|storage                       parapluie-32-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|openstack                     parapluie-8-kavlan-16.rennes.grid5000.fr|
|                              parapluie-32-kavlan-16.rennes.grid5000.fr|
|                              parapluie-35-kavlan-16.rennes.grid5000.fr|
|                              parapluie-38-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|compute                       parapluie-8-kavlan-16.rennes.grid5000.fr|
|                              parapluie-38-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|frontend                      rennes                                  |
+----------------------------------------------------------------------+
```
* ssh to controller as root
* (controller) ```source openrc```
* (controller) ```nova-manage service list | sort```

```bash
Binary           Host                                 Zone             Status     State Updated_At
nova-cert        parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:18
nova-cert        parapluie-38-kavlan-16.rennes.grid5000.fr internal         enabled    XXX   None
nova-compute     parapluie-38-kavlan-16.rennes.grid5000.fr nova             enabled    :-)   2014-10-07 14:49:17
nova-compute     parapluie-8-kavlan-16.rennes.grid5000.fr nova             enabled    :-)   2014-10-07 14:49:24
nova-conductor   parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:24
nova-consoleauth parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:19
nova-network     parapluie-38-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:25
nova-network     parapluie-8-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:23
nova-scheduler   parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:24
```

## Boot VMs

### Using Nova

```
# use demo user
(controller) source demorc
(controller) nova boot --flavor 3 --security_groups vm_jdoe_sec_group --image ubuntu-13.10 --nic net-id=a665bfd4-53da-41a8-9bd6-bab03c09b890 --key_name jdoe_key  ubuntu-vm
```

Note : Get the list of nets / images  ...
```
nova net-list
nova image-list
nova secgroup-list
nova keypair-list
````


### Using EC2


```
# check access/secret key
(controller) cat demo.ec2
(controller) EC2_ACCESS_KEY=224de6d07e5342dea886f64384e8d27e EC2_SECRET_KEY=8d70469c8fba4b7194d1f0276d33b813 EC2_URL=http://10.27.204.144:8773/services/Cloud euca-run-instances -n 1 -g vm_jdoe_sec_group -k jdoe_key -t m1.medium ubuntu-13.10
```

### Using the web interface

```
(laptop) ssh -NL 8000:parapluie-32-kavlan-16.rennes.grid5000.fr:80 access.grid5000.fr
```
And then visit ```http://127.0.0.1:8000/horizon```

## Miscellaneous

### Setting a cron job

In order to automate the deployment every working day in the morning, a good solution is to use a [cron](http://en.wikipedia.org/wiki/Cron) on a frontend of Grid5000. 

Before creating the cron, you should create a bash script containing the commands you need to execute. Here after, an example:

```
#!/bin/bash
cd /home/<username>/<capi5k-openstack-folder>
/home/<username>/.gem/ruby/1.9.1/gems/capistrano-2.15.5/bin/cap automatic > stdout.log 2> stderr.log
```

To create the cron, type `crontab -e` and put this line at the end:

```
0 9 * * mon-fri ~/deploy.bash
```

The script _deploy.bash_ will be executed at 9AM from Monday to Friday every week. 
