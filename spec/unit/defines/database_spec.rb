require 'spec_helper'

describe 'wordpress_app::database', :type => :define do
  let :facts do
    {
      :operatingsystem => 'CentOS',
      :operatingsystemmajrelease => '7',
      :osfamily => 'Redhat',
    }
  end

  let(:title) { 'public_blog' }

  context 'with defaults for all parameters' do
    it { should compile }
    it { should contain_wordpress_app__database('public_blog') }
  end
end
