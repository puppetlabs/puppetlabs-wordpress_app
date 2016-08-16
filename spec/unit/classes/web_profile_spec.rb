require 'spec_helper'

describe 'wordpress_app::web_profile', :type => :class do
  let :facts do
    {
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0',
      :operatingsystemmajrelease => '7',
      :osfamily => 'RedHat',
    }
  end

  context 'with defaults for all parameters' do
    it { should compile }
    it { should contain_class('wordpress_app::web_profile') }
  end
end
