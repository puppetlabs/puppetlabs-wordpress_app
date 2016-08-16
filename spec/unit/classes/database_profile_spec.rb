require 'spec_helper'

describe 'wordpress_app::database_profile', :type => :class do
  let :facts do
    {
      :operatingsystem => 'CentOS',
      :operatingsystemmajrelease => '7',
      :osfamily => 'Redhat',
    }
  end

  context 'with defaults for all parameters' do
    it { should compile }
    it { should contain_class('wordpress_app::database_profile') }
  end
end
