require 'spec_helper'

describe 'puppet::master::apache', :type => :class do
  let(:node) { 'master.nvisionary.com' }
  let :fact_defaults do
    {
      :ipaddress      => '192.168.1.111',
      :environment    => 'production',
      :domain         => 'nvisionary.com',
      :concat_basedir => '/tmp',
    }
  end
  describe 'with operatingsystem specific facts' do
    {
      'Ubuntu-12.04' => {
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :osfamily               => 'Debian'
      },
    }.each do |ossystem, osfacts|

      describe "when operatingsystem is #{ossystem}" do
        let :facts do
          fact_defaults.merge(osfacts)
        end
        
        it { should include_class('puppet::params') }
        it { should include_class('puppet::master') }
        it { should include_class('passenger') }
        it { should include_class('apache::mod::headers') }
        it { should include_class('apache::mod::ssl') }
        it { should contain_class('puppet::master').with(
          'type' => 'apache'
          )
        }
        it { should include_class('puppet::master::apache::configure') }
        
        directories = {
          'rackdir'       => '/usr/share/puppet/rack',
          'puppetmasterd' => '/usr/share/puppet/rack/puppetmasterd',
          'publicdir'     => '/usr/share/puppet/rack/puppetmasterd/public',
          'tmpdir'        => '/usr/share/puppet/rack/puppetmasterd/tmp'
        }.each do |dir, path|
          it { should contain_file(path).with(
            'ensure' => 'directory',
            'owner'  => 'root',
            'group'  => 'root'
            )
          }
        end
        it { should contain_file('/usr/share/puppet/rack/puppetmasterd/config.ru').with(
          'ensure'  => 'file',
          'owner'   => 'puppet',
          'group'   => 'puppet',
          'notify'  => 'Service[httpd]',
          'require' => 'File[/usr/share/puppet/rack/puppetmasterd]'
          )
        }
        it 'should have a file config.ru with the correct contents' do
          verify_template(subject, '/usr/share/puppet/rack/puppetmasterd/config.ru', [
            'ARGV << "--confdir" << "/etc/puppet"',
            'ARGV << "--vardir"  << "/var/lib/puppet"',
          ])
        end
        it { should contain_exec('generate_master-cert').with(
          'path'      => '/bin:/sbin:/usr/bin:/usr/sbin',
          'cwd'       => '/etc/puppet',
          'command'   => 'puppet cert generate $(puppet master --configprint certname)',
          'unless'    => 'test -e /etc/puppet/ssl/certs/master.nvisionary.com.pem',
          'logoutput' => 'on_failure',
          'require'   => 'Class[Puppet::Master::Configure]'
        )}
        it { should contain_apache__vhost('puppetmaster').with(
          'priority'        => '10',
          'vhost_name'      => '*',
          'port'            => '8140',
          'options'         => 'None',
          'custom_fragment' => %r{RackBaseURI /\n},
          'docroot'         => '/usr/share/puppet/rack/puppetmasterd/public',
          'logroot'         => '/var/log/puppet'
          )
        }
        it 'should have a file 10-puppetmaster.conf with the correct contents' do
          verify_template(subject, '10-puppetmaster.conf', [
            '<VirtualHost \*:8140>',
            'SSLCertificateFile      /etc/puppet/ssl/certs/master.nvisionary.com.pem',
            'SSLCertificateKeyFile   /etc/puppet/ssl/private_keys/master.nvisionary.com.pem',
            'SSLCertificateChainFile /etc/puppet/ssl/certs/ca.pem',
            'SSLCACertificateFile    /etc/puppet/ssl/certs/ca.pem',
            'SSLCARevocationFile     /etc/puppet/ssl/ca/ca_crl.pem',
            'DocumentRoot /usr/share/puppet/rack/puppetmasterd/public',
            '<Directory /usr/share/puppet/rack/puppetmasterd/public>',
            'Options None',
            'AllowOverride None',
            'Order allow,deny',
            'Allow from all',
            'RackBaseURI /'
          ])
        end  
        
      end
    end
  end
end
