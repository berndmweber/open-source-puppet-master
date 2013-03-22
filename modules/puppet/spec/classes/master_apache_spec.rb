require 'spec_helper'

describe 'puppet::master::apache', :type => :class do
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
        it { should contain_class('puppet::master').with(
          'type' => 'apache'
          )
        }
        it { should include_class('puppet::master::apache::configure') }
        
        it { should contain_apache__vhost('puppetmaster').with(
          'priority'   => '10',
          'vhost_name' => '*',
          'port'       => '8140',
          'template'   => 'puppet/puppetmaster.conf.erb',
          'docroot'    => '/usr/share/puppet/rack/puppetmasterd/',
          'logroot'    => '/var/log/puppet'
          )
        }
        it 'should have a file 10-puppetmaster.conf with the correct contents' do
          verify_template(subject, '10-puppetmaster.conf', [
            'Listen 8140',
            '<VirtualHost \*:8140>',
            'SSLCertificateFile      /etc/puppet/ssl/certs/master.copperfroghosting.net.pem',
            'SSLCertificateKeyFile   /etc/puppet/ssl/private_keys/master.copperfroghosting.net.pem',
            'SSLCertificateChainFile /etc/puppet/ssl/certs/ca.pem',
            'SSLCACertificateFile    /etc/puppet/ssl/certs/ca.pem',
            'SSLCARevocationFile     /etc/puppet/ssl/ca/ca_crl.pem',
            'DocumentRoot /usr/share/puppet/rack/puppetmasterd/public',
            '<Directory /usr/share/puppet/rack/puppetmasterd/>'
          ])
        end  
        
      end
    end
  end
end
