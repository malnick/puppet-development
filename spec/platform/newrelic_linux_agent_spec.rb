require 'spec_helper'

describe 'newrelic_linux_agent_test' do

  newrelic_files = ['/etc/newrelic/nrsysmond.cfg','/var/log/newrelic/nrsysmond.log','/var/run/newrelic/nrsysmond.pid']
  
  newrelic_files.each do |file|
    describe file(file) do
      it { should be_file }
    end
  end

  describe package('newrelic-sysmond') do
     it { should be_installed }
  end

  describe service('newrelic-sysmond') do
    it { should be_enabled }
    it { should be_running }
  end

end
