require 'spec_helper'

describe 'puppet', :type => :class do
  context "On a Ubuntu 12.04 system" do
    let :facts do
      { :operatingsystem => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :ipaddress => '192.168.1.111'
      }
    end
    let(:node) { 'puppet.copperfroghosting.net' }
  
    it { should include_class('puppet::install') }
    it { should include_class('puppet::service') }
  end
end
