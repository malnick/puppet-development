require 'spec_helper'

pkgs = [
  'git',
  'cgroup-lite', 
  'unzip',
  'oracle-java8-installer',
  'docker',
]

describe 'platform_packages_test' do
  pkgs.each do |p|
    describe package(p) do
      it { should be_installed }
    end
  end
end
