require 'spec_helper'

describe 'wordpress_app::lb', :type => :define do
  let(:facts) {{
    :operatingsystem => 'CentOS',
    :operatingsystemmajrelease => '7',
    :osfamily => 'RedHat',
    :ipaddress => '1.1.1.1',
  }}

  let :title do
    'test'
  end
  let(:params) {{
    :balancermembers => [{
      "host" => 'foo',
      "ip" => '1.1.1.1',
      "port" => 80,
    }]
  }}

  describe 'should work with only default parameters' do
    it { is_expected.to contain_wordpress_app__lb('test') }
  end
end
