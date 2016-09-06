require 'spec_helper'

describe 'wordpress_app::simple', :type => :application do
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

  context "on a single node" do
    let(:node) { 'blog.puppet.com' }

    let :params do
      {
        :nodes => {
          ref('Node', node) => [
            ref('Wordpress_app::Lb', title),
            ref('Wordpress_app::Web', title),
            ref('Wordpress_app::Database', title),
          ]
        }
      }
    end

    context 'with defaults for all parameters' do
      it { should compile }
      it { should contain_wordpress_app__simple(title).with(
                    'database' => 'wordpress',
                    'db_user' => 'wordpress',
                    'db_pass' => 'wordpress',
                    'web_port' => 8080,
                    'lb_port' => '80',
                  ) }
      it { should contain_wordpress_app__lb(title).with(
                    'lb_options' => ['forwardfor', 'http-server-close', 'httplog'],
                    'ipaddress' => '0.0.0.0',
                    'port' => '80',
                  ) }
      it { should contain_wordpress_app__web(title).with(
                    'db_host' => node,
                    'db_name' => 'wordpress',
                    'db_user' => 'wordpress',
                    'db_password' => 'wordpress',
                    'interface' => '',
                    'apache_port' => 8080,
                  ) }
      it { should contain_wordpress_app__database(title).with(
                    'database' => 'wordpress',
                    'user' => 'wordpress',
                    'password' => 'wordpress',
                  ) }
    end
  end
end
