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
            ':datadir: /etc/puppet/hieradata',
            ])
        end
        it { should contain_file('/etc/puppet/hieradata').with(
          'ensure'  => 'directory',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'require' => 'File[/etc/puppet/hiera.yaml]'
          )
        }
        it { should contain_file('/etc/puppet/hieradata/common.yaml').with(
          'ensure'  => 'file',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0755',
          'require' => 'File[/etc/puppet/hieradata]'
          )
        }
      end
    end
  end
end