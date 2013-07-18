require 'spec_helper'

describe 'puppet::test::rspec', :type => :class do
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
        it { should include_class('puppet::test::rspec::install') }
        it { should include_class('puppet::test::rspec::configure') }

        it { should contain_exec('install-rspec-puppet').with(
          'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
          'command' => 'gem install rdoc && gem install rspec-puppet',
          'creates' => '/usr/local/bin/rspec-puppet-init',
          'require' => 'Class[Ruby]'
        )}
        it { should contain_exec('install-rspec-puppetlabs_spec_helper').with(
          'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
          'command' => 'gem install puppetlabs_spec_helper',
          'unless'  => 'gem list --local | grep puppetlabs_spec_helper',
          'require' => 'Exec[install-rspec-puppet]'
        )}
        it { should contain_exec('install-rspec-puppet-augeas').with(
          'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
          'command' => 'gem install rspec-puppet-augeas',
          'unless'  => 'gem list --local | grep rspec-puppet-augeas',
          'require' => 'Exec[install-rspec-puppetlabs_spec_helper]'
        )}

      end
    end
  end
end