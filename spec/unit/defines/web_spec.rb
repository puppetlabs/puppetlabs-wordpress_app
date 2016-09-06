# coding: utf-8
require 'spec_helper'

describe 'wordpress_app::web', :type => :define do
  let :facts do
    {
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0',
      :operatingsystemmajrelease => '7',
      :osfamily => 'RedHat',
      :ipaddress => '1.1.1.1',
    }
  end

  let(:title) { 'public_blog' }

  let :params do
    {
      :db_host => 'db.puppet.com',
      :db_name => 'wordpress',
      :db_user => 'wordpress_app',
      :db_password => 'déjame_entrar_señor',
    }
  end

  context 'with defaults for all parameters' do
    it { should compile }
    it { should contain_wordpress_app__web('public_blog') }
  end
end
