require 'spec_helper'

describe 'wordpress_app::database', :type => :define do
  let :title do
    'test'
  end

  let(:facts) {{
    :operatingsystem => 'CentOS',
    :operatingsystemmajrelease => '7',
    :osfamily => 'Redhat',
  }}

  describe 'should work with only default parameters' do
    it { is_expected.to contain_wordpress_app__database('test') }
  end
end
