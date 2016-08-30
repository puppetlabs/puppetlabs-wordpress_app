require 'spec_helper'

describe 'wordpress_app::web_profile', :type => :class do
  context 'with defaults for all parameters' do
    let(:facts) {{
      :operatingsystem => 'CentOS',
      :operatingsystemrelease => '7.0',
      :operatingsystemmajrelease => '7',
      :osfamily => 'RedHat',
    }}
    it { should contain_class('wordpress_app::web_profile') }
  end
end
