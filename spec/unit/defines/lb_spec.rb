require 'spec_helper'

describe 'wordpress_app::lb', :type => :define do
  let :facts do
    {
      :operatingsystem => 'CentOS',
      :operatingsystemmajrelease => '7',
      :osfamily => 'RedHat',
      :ipaddress => '1.1.1.1',
    }
  end

  let(:title) { 'public_blog' }

  let(:params) do
    {
      :balancermembers => [
        {
          "host" => 'foo',
          "ip" => '1.1.1.1',
          "port" => 80,
        }
      ]
    }
  end

  context 'with defaults for all parameters' do
    it { should compile }
    it { should contain_wordpress_app__lb('public_blog') }
  end
end
