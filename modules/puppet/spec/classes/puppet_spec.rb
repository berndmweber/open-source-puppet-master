require 'spec_helper'

describe 'puppet', :type => :class do
  context "On a Ubuntu 12.04 system" do
    let(:params) {{}}
    let(:node) { 'puppet.copperfroghosting.net' }
    let :facts do
      { :operatingsystem => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :ipaddress => '192.168.1.111',
        :environment => 'production'
      }
    end
  
    it { should include_class('puppet::params') }
    it { should include_class('puppet::install') }
    it { should include_class('puppet::service') }

    it { should contain_package("puppet") }

    it { should contain_file("/etc/puppet").with(
      'ensure'  => 'directory',
      'owner'   => 'puppet',
      'group'   => 'root',
      'require' => 'Class[Puppet::Install]'
      )
    }
    it { should contain_file("/etc/puppet/puppet.conf").with(
      'ensure'  => 'file',
      'require' => 'File[/etc/puppet]'
      )
    }
    it 'should have a template with the correct contents' do
      content = catalogue.resource('file', '/etc/puppet/pupptet.conf').send(:parameters)[:content]
      content.should match("vardir = /var/lib/puppet")
      content.should match("logdir = /lor/log/puppet")
      content.should match("rundir = /var/run/puppet")
      content.should match("ssldir = /etc/puppet/ssl")
      content.should match("modulepath = /etc/puppet/modules")
    end  
      
    it { should contain_service("puppet").with(
      'ensure'     => 'running',
      'hasstatus'  => 'true',
      'hasrestart' => 'true',
      'enable'     => 'true',
      'require'    => 'Class[Puppet::Configure]'
      )
    }
  end
end
