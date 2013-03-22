require 'spec_helper'

describe 'puppet::master::module', :type => :define do
  let :title do
    'apache'
  end
  let :constant_default_params do
    {
      'ensure'              => 'present',
      'ignore_dependencies' => false,
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
          osfacts
        end
        
        describe "with contributor specified" do
          {
            'puppetlabs'        => {},
            'copperfroghosting' => {}
          }.each do |contrib, cparams|
            
            describe "when contributor is #{contrib}" do
              let :default_params do
                {
                 :contributor => contrib
                }.merge(constant_default_params)               
              end
              let :params do
                default_params.merge(cparams)
              end
              it { should include_class('puppet::params') }
              it { should contain_exec("install-#{title}-module").with(
                'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
                'command' => "puppet module install #{params[:contributor]}/#{title} ",
                'creates' => "/etc/puppet/modules/#{title}",
                'require' => 'Class[Puppet::Configure]'
              )}
            end
          end
        end          
      end
    end
  end  
end
