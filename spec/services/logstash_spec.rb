require 'spec_helper'

registry = 'docker.ec2.srcclr.com:5000'

describe 'services_base_test' do

  describe docker_image("#{registry}/srcclr_logstash:jut") do
    it { should exist }
  end

  describe docker_container("logstash-jut") do
    it { should be_running }
    it { should have_volume("/tmp","/var/lib/docker/vfs/dir") }
  end

end
