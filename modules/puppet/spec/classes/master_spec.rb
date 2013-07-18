require 'spec_helper'

describe 'puppet::master', :type => :class do
  let(:node) { 'master.nvisionary.com' }
  let :fact_defaults do
    {
      :ipaddress   => '192.168.1.111',
      :environment => 'production',
      :domain      => 'nvisionary.com'
    }
  end
  let :default_params do
    {
      :enable_hiera => true
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
        describe "with type specified" do
          {
            'self' => {
              :package     => 'puppetmaster',
              :service     => 'puppetmaster',
              :has_service => true
            },
            'apache' => {
              :package     => 'puppetmaster-common',
              :service     => 'httpd',
              :has_service => false
            }
          }.each do |pmtype, pmparams|
            
            describe "when type #{pmtype}" do
              let :params do
                {
                  :type => pmtype,
                }.merge(default_params)
              end
              it { should include_class('puppet::params') }
              it { should include_class('puppet') }
              it { should include_class('puppet::install') }
              it { should include_class('puppet::configure') }
              it { should include_class('puppet::service') }
              
              it { should contain_package(pmparams[:package]) }
              
              context 'puppet class now configures the system for the master setup' do
                it { should contain_file('/etc/puppet').with(
                  'ensure'  => 'directory',
                  'owner'   => 'puppet',
                  'group'   => 'root',
                  'require' => 'Class[Puppet::Install]'
                  )
                }
                it { should contain_file('/etc/puppet/puppet.conf').with(
                  'ensure'  => 'file',
                  'require' => 'File[/etc/puppet]',
                  'notify'  => "Service[#{pmparams[:service]}]"
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
                    'archive_file_server = master.nvisionary.com',
                    'certname = master.nvisionary.com',
                    'server = master.nvisionary.com',
                    '\[master\]',
                    'certname = master.nvisionary.com',
                    'dns_alt_names = puppet,puppet.nvisionary.com,master,master.nvisionary.com',
                    '\[testing\]\n\s*modulepath = /etc/puppet/environments/testing/modules:/etc/puppet/modules\n\s*manifest = /etc/puppet/environments/testing/manifests/site.pp',
                    '\[development\]\n\s*modulepath = /etc/puppet/environments/development/modules:/etc/puppet/modules\n\s*manifest = /etc/puppet/environments/development/manifests/site.pp',
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
              end
              
              describe_augeas '/etc/default/puppet', :lens => 'Shellvars.lns', :target => '/etc/default/puppet' do
                it 'should change the contents of /etc/default/puppet' do
                  should execute.with_change
                  aug_get('START').should == 'yes'
                  should execute.idempotently
                end
              end
              it { should contain_file('/etc/puppet/fileserver.conf').with(
                'ensure'  => 'file',
                'require' => 'File[/etc/puppet]',
                'notify'  => "Service[#{pmparams[:service]}]"
                )
              }
              it 'should have a file fileserver.conf with the correct contents' do
                verify_template(subject, '/etc/puppet/fileserver.conf', [
                  '# This file is controlled by puppet. Do NOT edit! #',
                ])
              end  
              it { should contain_file('/var/lib/puppet/reports').with(
                'ensure'  => 'directory',
                'owner'   => 'puppet',
                'group'   => 'puppet',
                'recurse' => true
                )
              }
              it { should contain_file('/etc/puppet/ssl').with(
                'ensure' => 'directory',
                'owner'  => 'puppet',
                'group'  => 'root',
                'mode'   => '0771'
                )
              }
              it { should contain_file('/etc/puppet/manifests').with(
                'ensure'  => 'directory',
                'owner'   => 'root',
                'group'   => 'root',
                'recurse' => true,
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/modules').with(
                'ensure'  => 'directory',
                'owner'   => 'root',
                'group'   => 'root',
                'recurse' => true,
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/manifests/site.pp').with(
                'ensure'  => 'file',
                'require' => 'File[/etc/puppet/manifests]'
                )
              }
              it 'should have a file site.pp with the correct contents' do
                verify_template(subject, '/etc/puppet/manifests/site.pp', [
                  'server => \'master.nvisionary.com\',',
                  'node /master.nvisionary.com/ \{'
                ])
              end  
              it { should contain_file('/etc/puppet/environments').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/environments/testing').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/environments/testing/modules').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/environments/testing/manifests').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/environments/development').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/environments/development/modules').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              it { should contain_file('/etc/puppet/environments/development/manifests').with(
                'ensure'  => 'directory',
                'require' => 'File[/etc/puppet]'
                )
              }
              
              if pmparams[:has_service]
                it { should contain_service('puppetmaster').with(
                  'ensure'  => 'running',
                  'enable'  => 'true',
                  'require' => 'Class[Puppet::Master::Install]'
                  )
                }
              else
                it { should_not contain_service('puppetmaster') }
              end
              it { should include_class('puppet::master::hiera') }
            end
          end
        end
      end
    end
  end
end