require 'spec_helper'

describe 'puppet::master::hiera', :type => :class do
  let(:node) { 'master.nvisionary.com' }
  let :fact_defaults do
    {
      :ipaddress   => '192.168.1.111',
      :environment => 'production',
      :domain      => 'nvisionary.com'
    }
  end
  describe 'with operatingsystem specific facts' do
    {
      'Ubuntu-12.04' => {
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04'
      },
    }.each do |ossystem, osfacts|

      describe "when operatingsystem is #{ossystem}" do
        let :facts do
          fact_defaults.merge(osfacts)
        end
        it { should include_class('puppet::params') }
        it { should include_class('puppet::master::hiera::install') }
        it { should include_class('puppet::master::hiera::configure') }
          
        it { should contain_package('hiera-gpg').with(
          'provider' => 'gem'
          )
        }
        
        it { should contain_file('/etc/puppet/hiera.yaml').with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'require' => 'File[/etc/puppet]'
          )
        }
        it 'should have a file hiera.yaml with the correct contents' do
          verify_template(subject, '/etc/puppet/hiera.yaml', [
            ':datadir: /etc/puppet/environments/%\{environment\}/hieradata',
            ':key_dir: /var/lib/puppet/.gnupg'
            ])
        end
        it { should contain_file('/etc/puppet/environments/production/hieradata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'require' => 'File[/etc/puppet/hiera.yaml]'
          )
        }
        it { should contain_file('/etc/puppet/environments/development/hieradata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'require' => 'File[/etc/puppet/hiera.yaml]'
          )
        }
        it { should contain_file('/etc/puppet/environments/testing/hieradata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'require' => 'File[/etc/puppet/hiera.yaml]'
          )
        }
        it { should contain_file('/etc/puppet/environments/production/hieradata/common.yaml').with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/etc/puppet/environments/production/hieradata/master.nvisionary.com.yaml').with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/etc/puppet/environments/testing/hieradata/common.yaml').with(
          'ensure'  => 'file',
          'replace' => false,
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/etc/puppet/environments/development/hieradata/common.yaml').with(
          'ensure'  => 'file',
          'replace' => false,
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/etc/puppet/environments/production/hieradata/passwords.yaml').with(
          'ensure'  => 'file',
          'replace' => false,
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'source'  => 'puppet:///modules/puppet/hieradata/passwords.yaml',
          'require' => 'File[/etc/puppet/environments/production/hieradata]'
          )
        }
        it { should contain_file('/etc/puppet/environments/testing/hieradata/passwords.yaml').with(
          'ensure'  => 'file',
          'replace' => false,
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'source'  => 'puppet:///modules/puppet/hieradata/passwords.yaml',
          'require' => 'File[/etc/puppet/environments/testing/hieradata]'
          )
        }
        it { should contain_file('/etc/puppet/environments/development/hieradata/passwords.yaml').with(
          'ensure'  => 'file',
          'replace' => false,
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'source'  => 'puppet:///modules/puppet/hieradata/passwords.yaml',
          'require' => 'File[/etc/puppet/environments/development/hieradata]'
          )
        }
        it { should contain_file('/etc/puppet/environments/production/hieradata/gpgdata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/etc/puppet/environments/development/hieradata/gpgdata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/etc/puppet/environments/testing/hieradata/gpgdata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755'
          )
        }
        it { should contain_file('/var/lib/puppet/.gnupg').with(
          'ensure'  => 'directory',
          'owner'   => 'puppet',
          'group'   => 'puppet',
          'mode'    => '0700',
          'require' => 'File[/var/lib/puppet]'
          )
        }
        it { should contain_file('/etc/puppet/gpgdata').with(
          'ensure'  => 'directory',
          'owner'   => 'puppet',
          'group'   => 'puppet',
          'mode'    => '0700',
          'require' => 'File[/etc/puppet]'
          )
        }
      end
    end
  end
end