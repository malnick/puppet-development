begin

  require 'rubygems'
  require 'os'
  require 'yaml'
  require 'net/http'
  require 'aws-sdk'
  require 'logger'
  require 'git'
  require 'rspec/core/rake_task'

rescue LoadError => e

  puts "Error during requires: \t#{e.message}"
  abort "You may be able to fix this problem by running 'bundle'."

end

# 'class' vars
LOG                     = Logger.new(STDOUT)
AWS_CONFIG              = "#{ENV['HOME']}/.aws.yaml"

DATABASE_BUCKET         = 'bucket'
DATABASE_KEY            = 'key'
THISDIR                 = File.expand_path(File.dirname(__FILE__))
SOURCECLEAR_PUPPETFILE  = 'git@github.com:sourceclear/puppet-control.git'
PUPPET_ENV              = ENV['PUPPET_ENV']
MODULE                  = ENV['module']

namespace :reload do
  desc 'Redeploy modules to the puppetmaster'
  task :modules do
    IO.popen("r10k deploy environment --puppetfile -v debug -c r10k.yaml") do |o|
        LOG.info(o.readlines)
    end
  end

  task :module do 
    IO.popen("r10k deploy module #{MODULE} -v debug -c r10k.yaml") do |o|
      LOG.info(o.readlines)
    end
  end

  task :master do 
    system("vagrant reload master && vagrant provision master")
  end 

  task :all => [:modules, :master]
end
 
# Do the setup as defualt for 'rake'
task :default => 'deps'

# Setup what we should have and how it's structured
necessary_programs  = %w(VirtualBox vagrant)

necessary_plugins   = %w(vagrant-hosts vagrant-auto_network vagrant-pe_build)

dir_structure       = %w(r10k r10k/cache puppet puppet/filestore puppet/environments)

desc 'Check for the environment dependencies'
task :deps do
  puts 'Checking environment dependencies...'

  printf "Is this a POSIX OS?..."
  unless OS.posix?
    abort 'Sorry, you need to be running Linux or OSX to use this Vagrant environment!'
  end
  puts "OK"

  necessary_programs.each do |prog|
    printf "Checking for %s...", prog
    unless system("which #{prog}")
      abort "\nSorry but I didn't find required program \'#{prog}\' in your PATH.\n"
    end
    puts "OK"
  end

  necessary_plugins.each do |plugin|
    printf "Checking for vagrant plugin %s...", plugin
    unless %x{vagrant plugin list}.include? plugin
      puts "\nSorry, I wasn't able to find the Vagrant plugin \'#{plugin}\' on your system, running 'rake setup'."
      Rake::Task['setup'].execute
    end
    puts "OK"
  end

  puts "Checking respository structure..."
  Rake::Task["create_structure"].execute


  puts "\n"
  puts '*' * 80
  puts "Congratulations! Everything looks a-ok."
  puts '*' * 80
  puts "\n"
end

desc 'Install the necessary Vagrant plugins'
task :setup do
  necessary_plugins.each do |plugin|
    unless system("vagrant plugin install #{plugin} --verbose")
      abort "Install of #{plugin} failed. Exiting..."
    end
  end
end

desc "Create dir structure"
task :create_structure do
puts "Checking CWD for directory structure..."
  dir_structure.each do |d|
	cwd = Dir.getwd
	check_dir = "#{cwd}/#{d}"
	if Dir.exists?(check_dir)
		puts "#{check_dir} exists, moving on."
	else
		puts "#{check_dir} does not exist, creating it."
		Dir.mkdir("#{check_dir}", 0777)
	end
  end
end


# Deploy this environment
desc 'deploy'
task :deploy do
# This section may come in handy later...
#    unless File.exists?(AWS_CONFIG)
#        abort LOG.error(%{
#            Sorry, I couldn't find AWS config file: #{AWS_CONFIG}\n
#            Please ensure ~/.aws.yaml exits and has the following strucutre:\n
#            ---\n
#            access_key_id: 'myaccesskeyid'\n
#            secret_access_key: 'mysecretaccesskey'\n
#        }) 
#    end
#
#    LOG.info('Found ~/.aws.yaml')
#    config = YAML.load(File.open(AWS_CONFIG, 'r'))
#
#    s3 = Aws::S3::Client.new(
#        :access_key_id          => config['access_key_id'],
#        :secret_access_key      => config['secret_access_key'],
#        :region                 => config['region'] || 'us-east-1'
#    )
#
#    unless File.exists?("puppet/filestore/database.sql")
#        LOG.info("No local database dump found, pulling from S3")
#        s3.get_object(
#            response_target:    "puppet/filestore/database.sql",
#            bucket:             DATABASE_BUCKET, 
#            key:                DATABASE_KEY
#        )
#    end

    LOG.info("Writing r10k.yaml configuration")
    r10k_config = {
        'sources'   => {
            'sourceclear' => {
                'remote'    => SOURCECLEAR_PUPPETFILE,
                'basedir'   => "#{THISDIR}/puppet/environments"
                }
            }
        }

    # If the r10k config exists lets make sure we append and not overwrite the entire thing to keep customization possible
    if File.exists?('r10k.yaml') && YAML.load('r10k.yaml')
        LOG.info("Found r10k.yaml, configuring...")
        
        r10k_config = YAML.load_file('r10k.yaml') 
        
        File.open('r10k.yaml', 'w') do |file|
            r10k_config['sources']['sourceclear']['remote']       = SOURCECLEAR_PUPPETFILE
            r10k_config['sources']['sourceclear']['basedir']      = "#{THISDIR}/puppet/environments"
            file.write(YAML.dump(r10k_config))
    end

    # If it doesn't exist you're not customizing shit so I'm starting from scratch
    else
        LOG.info("Creating r10k.yaml")
        File.delete('r10k.yaml') if File.exists?('r10k.yaml')
        File.open('r10k.yaml', 'w') do |f|
            f.write(YAML.dump(r10k_config))
        end
    end

    # Pull down our Puppet code 
    IO.popen("r10k deploy environment --puppetfile -v debug -c r10k.yaml") do |o|
        LOG.info(o.readlines)
    end
       

    # Update puppet/manifests/site.pp
    unless Dir.exists? ('puppet/manifests')
        Git.clone('git@github.com:sourceclear/puppet-site.git', 'manifests', :path => "#{THISDIR}/puppet", :log => LOG)
    end
    

    LOG.info("Bringing up environment...")
    if PUPPET_ENV
      system("PUPPET_ENV=#{PUPPET_ENV} vagrant up --provider virtualbox") 
    else
      system("vagrant up --provider virtualbox") 
    end

    sleep(300)

    Rake::Task["spec"].execute
    
end


  task :spec    => 'spec:all'
  task :default => :spec
  namespace :spec do
    targets = []
    Dir.glob('./spec/*').each do |dir|
      next unless File.directory?(dir)
      target = File.basename(dir)
      target = "_#{target}" if target == "default"
      targets << target
    end

    task :all     => targets
    task :default => :all

    targets.each do |target|
      original_target = target == "_default" ? target[1..-1] : target
      desc "Run serverspec tests to #{original_target}"
      RSpec::Core::RakeTask.new(target.to_sym) do |t|
        ENV['TARGET_HOST'] = original_target
        t.pattern = "spec/#{original_target}/*_spec.rb"
      end
    end
  end
