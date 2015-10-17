require 'spec_helper'

registry = 'docker.ec2.srcclr.com:5000'
services = {
  'analytics' => {
    'svc_port'  => '11120',
    'mgmt_port' => '11130',
    'version'   => '0.0.16-SNAPSHOT',
  },  
  'librarian' => {
    'svc_port'  => '11060',
    'mgmt_port' => '11070',
    'version'   => '0.3.10'
  },
  'notifications' => {
    'svc_port'  => '11000',
    'mgmt_port' => '11010',
    'version'   => '0.0.12',
  },
  'cloud_scm_agent' => {
    'svc_port'  => '11040',
    'mgmt_port' => '11050',
    'version'   => '0.5.7-SNAPSHOT',
  },
  'vulnerabilities' => {  
    'svc_port'  => '11100',
    'mgmt_port' => '11110',
    'version'   => '0.0.4',
  },
  'webhooks' => {
    'svc_port'  => '11020',
    'mgmt_port' => '11030',
    'version'   => '0.0.20-SNAPSHOT',
  }
}
 
describe 'sc_services_docker_test' do
  services.each do |service, info|
    
    # Ensure the image is available on the box & has minimal configuration
    describe docker_image("#{registry}/#{service}-service:#{info['version']}") do
      
      it { should exist }
      
      its(:inspection) { should_not include 'Architecture' => 'i386' }
      
      its(['Config.Entrypoint']) { should include "java -Dnewrelic.enable.java.8 -Dnewrelic.config.file=/newrelic.yml -javaagent:/newrelic.jar -jar /#{service}-service.jar >> /log/#{service}_$(hostname).log 2>&1" }

      its(['Config.ExposedPorts']) { should include "#{info['svc_port']}/tcp" }

      its(['Config.Volumes']) { should include "/log" }
      
      # If the service has a mgmt port, check to ensure it's present in the config
      if info['mgmt_port']
        its(['Config.ExposedPorts']) { should include "#{info['mgmt_port']}/tcp" }
      end
    end

    # Ensure container is executed and 2 processes are running - this requires the $name value set by puppet which is somewhat jank
    describe docker_container("#{service}--#{info['version']}--1") do
      it { should be_running }
    end
    describe docker_container("#{service}--#{info['version']}--2") do
      it { should be_running }
    end


    # Ensure ports are exposed on the host
    describe port(info['svc_port']) do
      it { should be_listening }
    end
    if info['mgmt_port'] 
      describe port(info['mgmt_port']) do
        it { should be_listening }
      end
    end

  end
end
