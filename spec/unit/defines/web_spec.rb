require 'spec_helper'

describe 'wordpress_app::web', :type => :define do
  let(:facts) {{
    :operatingsystem => 'CentOS',
    :operatingsystemrelease => '7.0',
    :operatingsystemmajrelease => '7',
    :osfamily => 'RedHat',
    :ipaddress => '1.1.1.1',
  }}

  let :title do
    'test'
  end

  let(:params) {{
    :db_host => 'foo',
    :db_name => 'foo',
    :db_user => 'foo',
    :db_password => 'foo',
  }}

  describe 'should work with only default parameters' do
    it { is_expected.to contain_wordpress_app__web('test') }
  end
end
