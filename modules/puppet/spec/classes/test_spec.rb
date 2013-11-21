require 'spec_helper'

describe 'puppet::test', :type => :class do
  let :facts do
    {
      :environment            => 'production',
      :osfamily               => 'debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '12.04'
    }
  end
  describe 'with type specified' do
    {
      'rspec'    => {},
      'cucumber' => {},
    }.each do |ttype, tparams|
      describe "when #{ttype}" do
        let :params do
          {
            :type => ttype
          }
        end
        it { should include_class("puppet::test::#{ttype}") }
      end
    end  
  end
end
