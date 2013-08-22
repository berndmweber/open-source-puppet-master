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
        
        describe 'with contributor specified' do
          {
            'puppetlabs' => {},
            'nvisionary' => {}
          }.each do |contrib, cparams|
            
            describe "when contributor is #{contrib}" do
              
              describe 'with environment specified' do
                {
                  'production' => {},
                  'testing'    => {}
                }.each do |env, eparams|

                  describe "when environment is #{env}" do
                    
                    let :default_params do
                      {
                       :contributor => contrib,
                       :environment => env
                      }.merge(constant_default_params)
                    end
                    let :var_params do
                       default_params.merge(cparams)
                    end
                    let :params do
                      var_params.merge(eparams)
                    end
                    it { should include_class('puppet::params') }
                    if env == 'production'
                      it { should contain_exec("install-#{title}-module").with(
                        'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
                        'command' => "puppet module install #{params[:contributor]}/#{title}  ",
                        'creates' => "/etc/puppet/modules/#{title}",
                        'require' => 'Class[Puppet::Master::Configure]'
                      )}
                    else
                      it { should contain_exec("install-#{title}-module").with(
                        'path'    => '/bin:/sbin:/usr/bin:/usr/sbin',
                        'command' => "puppet module install #{params[:contributor]}/#{title}  --environment #{env}",
                        'creates' => "/etc/puppet/environments/#{env}/modules/#{title}",
                        'require' => 'Class[Puppet::Master::Configure]'
                      )}
                    end
                  end
                end
              end
            end
          end
        end          
      end
    end
  end  
end
