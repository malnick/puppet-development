# SRC:CLR DevEnviro

## What 
This is a local development environent for various parts of the SRC:CLR platform. It's meant as a testing environment so we don't have to do dev on aws or on localhost.

## Requirments
There are currently a few requirements:
1. No windows - sorry!
1. Vagrant - please install first
1. Access to a few private SRC:CLR repos for puppet code. Notably but not limited to puppet-profiles & puppet-roles

## How 
1. Install

```bash
git clone git@github.com:sourceclear/devenviro.git 
cd devenviro
```

2. Run it

```bash
# Checkout a specific environment:
git branch -a
   backend
   elk_stack
   main_stack
 * master
git checkout backend
rake        
rake deploy 
```

3. It's up, now what?
The entire point of this env is to replicate, at the most basic level, what is actually deployed in our QA and Prod environments in AWS. 

Now that the nodes are up, check the haproxy node to ensure the services are running:

1. **HaProxy**: Open a browser to ```http://10.33.100.14:22002```
User: sourceclear
PW:   sourceclear

1. **RabbitMQ**: Open a browser to ```http://10.33.100.11:15672```
User:  local
PW:    local

# Tests
All tests are located in ```spec/$server_role/*```

To run tests on the ```services``` node (test that the services node is provisioned correctly) execute:

```rake spec:services```

To test the platform node:

```rake spec:platform```

You can also run all tests with ```rake spec```

We use server-spec, which SSH's to the node to execute the tests. This might be a process we implement with CI via Jenkins in the future.

# Debugging
1. If the services are up, great. Move on to the next thing, otherwise:

  ```vagrant ssh services``` 

  Poke around and figure it out.

1. Test the services with some commands:
  1. Librarian: ```curl -vv 10.33.100.12/librarian``` or ```curl -LIv 10.33.100.12/librarian```
  2. Analytics:
  3. scm_agent:
  4: Notifications:
  5: Vulnerabilities:

1. Make recommendations on how to make this env more useful: jeff@sourceclear.com

1. On boot
  1. Check syslog for puppet provisioning errors: 

```
vagrant ssh services || datastore
tail -f /var/log/syslog
```

1. On already running vm:
  1. Check services node for errors:

```
vagrant ssh services
vi /mnt/librarian.log || analytics.log || scm_agent.log || notifications.log || vulnerabilities.log
```

## Reload
There are three subtasks for reloading this environment:

1. Reload and reprovision the master
```bash
rake reload:master
```

2. Run r10k to get new modules
```bash
rake reload:modules
```

3. Get new modules and reprovision the master -> need to run this if new modules include new sub directories which need to be symlinked back to the master.
```bash
rake reload:all
```
## What happened?
```rake``` is the default task. It installs the neccessary gems, plugins and other crap needed by the enviro. It also configures the directory structure of the repo to make sure everything is in place so puppet doesn't blow up. 

What? Pupp...et? p-u-p-p-e-t. It's a domain speficic language for configuration management that sits on top of Ruby. It looks a lot like cfengine or chef. 

Anyways... 

Every environment, for now and in the future, resolve to a different branch. Currently we have three branches:

1. elk_stack
1. main_stack
1. master

I created these first two stacks, the one you're intersted in is probably ```main_stack```:

1. services node
  1. This node acts like a backend services node in aws. It sits behind a loadbalancer and accespts requests to various services like:
    * librarian
    * scm_agent
    * analytics
    * vulnerabilities
    * other future services we roll
1. datastore
  1. Runs all our datastore services on a sinlge node; it mimics our RDS, MQ, ES, etc but in a single node:
    * Postgres
    * Mysql
    * RabbitMQ
    * ElasticSearch
    * Kibana
    * Redis
1. loadbalancer
  1. This mimics our internal loadbalancer that would usually sit between tomcat and our services nodes. It exists purely as a way to more elegantly convey what it's actually like in aws. We could connect directly to our services nodes butin reality we never test like that so we but this in place so we could curl the LB and not hte service directly. 
1. Puppetmaster 
  1. Like the PuppetMaster in aws, except local
    1. Feeds off the local puppet/ directory in this repo
    1. the ```puppet/``` dir is populated on ```rake deploy``` with all our module code to actually deploy these nodes.
    1. It's main puppet config dirs share the local directories in this environment
     


