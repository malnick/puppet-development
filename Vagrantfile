require 'yaml'
require 'net/http'
require 'logger'

LOG     = Logger.new(STDOUT)
THISDIR = File.expand_path(File.dirname(__FILE__))

def info(message)
    LOG.info(message)
end

def error(message)
    LOG.error(message)
end

PUPPET_ENV =  ENV['PUPPET_ENV'] || 'production' 

LOG.info "Building with Puppet environment #{PUPPET_ENV}"

VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntuamd64"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"
  config.pe_build.download_root = 'https://s3.amazonaws.com/pe-builds/released/:version'
  config.pe_build.version = "3.8.0"
  config.ssh.forward_agent  = true

## Master
  config.vm.define :master do |master|
    
    master.vm.provider :virtualbox do |v|
    	v.memory = 4098 
	    v.cpus = 2
    end
    
    master.vm.network :private_network, :ip => '10.33.100.10' 
    master.vm.hostname = 'master.vagrant.vm'
    master.vm.provision :hosts
    
    master.vm.provision :pe_bootstrap do |pe|
      pe.role = :master
    end

    # Environments
    master.vm.provision "shell", inline: "rm -rf /etc/puppetlabs/puppet/environments/production && ln -sf /tmp/environment /etc/puppetlabs/puppet/environments/production"
    
    # Filestore
    master.vm.provision "shell", inline: "rm -rf /etc/puppetlabs/puppet/filestore && ln -sf /tmp/filestore/ /etc/puppetlabs/puppet/"
    
    # Hiera.yaml
    master.vm.provision "shell", inline: "rm -f /etc/puppetlabs/puppet/hiera.yaml && ln -sf /vagrant/hiera.yaml /etc/puppetlabs/puppet"
    
    # Puppet Conf
    master.vm.provision "shell", inline: "rm -f /etc/puppetlabs/puppet/puppet.conf && ln -sf /vagrant/puppet.conf /etc/puppetlabs/puppet/puppet.conf"

    # eyaml
    master.vm.provision "shell", inline: "ln -sf /tmp/keys /etc/puppetlabs/puppet/ssl/keys"
    master.vm.provision "shell", inline: "test $(which eyaml) || /opt/puppet/bin/gem install hiera-eyaml"
    master.vm.provision "shell", inline: "/opt/puppet/bin/puppetserver gem install hiera-eyaml"
    master.vm.provision "shell", inline: "test -e /etc/eyaml || mkdir /etc/eyaml"
    master.vm.provision "shell", inline: "ln -sf /vagrant/eyaml.config /etc/eyaml/config.yaml" 
    
    # puppetmaster role
    master.vm.provision "shell", inline: 'echo "vagrant_puppetmaster" > /etc/role'

    # Install git
    master.vm.provision "shell", inline: 'apt-get install -y git'

    # Synced dirs
    master.vm.synced_folder "/Users/malnick/projects/puppet/environments/#{PUPPET_ENV}", "/tmp/environment"
    master.vm.synced_folder "puppet/", "/tmp/puppet"
    master.vm.synced_folder "puppet/filestore", "/tmp/filestore"
    master.vm.synced_folder "~/.eyaml", "/tmp/keys"

  end

  config.vm.define :testbox do |dev|

    dev.vm.provider :virtualbox do |v|
    	v.memory = 1024
	    v.cpus = 1
    end
 
    dev.vm.network :private_network, :ip => '10.33.100.11' 
    dev.vm.hostname = 'datastore.vagrant.vm'
    dev.vm.provision "shell", inline: 'echo "testbox" > /etc/role'
    dev.vm.provision :hosts
 
    dev.vm.provision :pe_bootstrap do |pe|
      pe.role   =  :agent
      pe.master = 'master.vagrant.vm'
    end
 
  end

end

