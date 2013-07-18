require 'spec_helper'

describe 'puppet', :type => :class do
  context 'On a Ubuntu 12.04 system' do
    let(:params) {{}}
    let(:node) { 'puppet.nvisionary.com' }
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

    it { should contain_package('puppet') }

    it { should contain_file('/etc/puppet').with(
      'ensure'  => 'directory',
      'owner'   => 'puppet',
      'group'   => 'root',
      'require' => 'Class[Puppet::Install]'
      )
    }
    it { should contain_file('/etc/puppet/puppet.conf').with(
      'ensure'  => 'file',
      'require' => 'File[/etc/puppet]'
      )
    }
    it 'should have a file puppet.conf with the correct contents' do
      verify_template(subject, '/etc/puppet/puppet.conf', [
        'vardir = /var/lib/puppet',
        'logdir = /var/log/puppet',
        'rundir = /var/run/puppet',
        'ssldir = /etc/puppet/ssl',
        'modulepath = /etc/puppet/modules',
        'user = puppet',
        'group = puppet',
        'archive_file_server = puppet.nvisionary.com',
        'certname = puppet.nvisionary.com',
        'server = puppet.nvisionary.com',
      ])
      verify_template_not(subject, '/etc/puppet/puppet.conf', [
        '\[master\]',
      ])
    end  
    it { should contain_file('/etc/puppet/auth.conf').with(
      'ensure'  => 'file',
      'require' => 'File[/etc/puppet]'
      )
    }
    it 'should have a file auth.conf with the correct contents' do
      verify_template(subject, '/etc/puppet/puppet.conf', [
        '# This file is controlled by puppet. Do NOT edit! #',
      ])
    end  
    it { should contain_file('/etc/default/puppet').with(
      'ensure'  => 'file',
      'require' => 'Class[Puppet::Install]'
      )
    }
    it { should contain_augeas('/etc/default/puppet').with(
      'context' => '/files/etc/default/puppet',
      'lens'    => 'Shellvars.lns',
      'incl'    => '/etc/default/puppet',
      'require' => 'File[/etc/default/puppet]'
      )
    }
    describe_augeas '/etc/default/puppet', :lens => 'Shellvars.lns', :target => '/etc/default/puppet' do
      it 'should change the contents of /etc/default/puppet' do
        should execute.with_change
        aug_get('START').should == 'yes'
        should execute.idempotently
      end
    end
      
    it { should contain_service('puppet').with(
      'ensure'     => 'running',
      'hasstatus'  => 'true',
      'hasrestart' => 'true',
      'enable'     => 'true',
      'require'    => 'Class[Puppet::Configure]'
      )
    }
  end
end
