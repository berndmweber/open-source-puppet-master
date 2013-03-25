require 'spec_helper'

describe 'puppet::test::cucumber', :type => :class do
  let(:node) { 'master.copperfroghosting.net' }
  let :fact_defaults do
    {
      :ipaddress   => '192.168.1.111',
      :environment => 'production',
      :domain      => 'copperfroghosting.net'
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
        it { should include_class('puppet::test::cucumber::install') }
        it { should include_class('puppet::test::cucumber::configure') }

        it { should contain_exec('install-cucumber-puppet').with(
          'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
          'command' => 'gem install rdoc && gem install cucumber-puppet',
          'creates' => '/usr/local/bin/cucumber-puppet',
          'require' => 'Class[Ruby]'
        )}
        directories = {
          'featuredir' => '/etc/puppet/features',
          'catalogdir' => '/etc/puppet/features/catalog',
          'supportdir' => '/etc/puppet/features/support',
          'yamldir'    => '/etc/puppet/features/yaml'
        }.each do |dir, path|
          it { should contain_file("#{path}").with(
            'ensure'  => 'directory'
            )
          }
        end
        it { should contain_file('/etc/puppet/features/support/hooks.rb').with(
          'ensure'  => 'file',
          'require' => 'File[/etc/puppet/features/support]'
          )
        }
        it 'should have a file hooks.rb with the correct contents' do
          verify_template(subject, '/etc/puppet/features/support/hooks.rb', [
            '\@puppetcfg\[\'confdir\'\] = "/etc/puppet"',
            '\@puppetcfg\[\'manifest\'\] = "/etc/puppet/manifests/site.pp"',
            '\@puppetcfg\[\'modulepath\'\] = "/etc/puppet/modules"',
          ])
        end
        it { should contain_file('/etc/puppet/features/support/world.rb').with(
          'ensure'  => 'file',
          'require' => 'File[/etc/puppet/features/support]'
          )
        }
        it { should contain_file('/etc/puppet/features/steps').with(
          'ensure'  => 'directory',
          'recurse' => true,
          'require' => 'File[/etc/puppet/features]'
          )
        }
        it { should contain_file('/etc/puppet/features/catalog/policy.feature').with(
          'ensure'  => 'file',
          'require' => 'File[/etc/puppet/features/catalog]'
          )
        }
        it 'should have a file policy.feature with the correct contents' do
          verify_template(subject, '/etc/puppet/features/catalog/policy.feature', [
            '    Given a node specified by "features/yaml/\<hostname\>.copperfroghosting.net.yaml"',
            '      \| master \|',
          ])
        end
        it { should contain_file('/etc/puppet/features/yaml/master.copperfroghosting.net.yaml').with(
          'ensure'  => 'file',
          'source'  => '/var/lib/puppet/yaml/node/master.copperfroghosting.net.yaml',
          'require' => 'File[/etc/puppet/features/yaml]'
          )
        }
      end
    end
  end
end