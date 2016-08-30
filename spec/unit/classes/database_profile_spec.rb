require 'spec_helper'

describe 'wordpress_app::database_profile', :type => :class do
  context 'with defaults for all parameters' do
    let(:facts) {{
      :operatingsystem => 'CentOS',
      :operatingsystemmajrelease => '7',
      :osfamily => 'Redhat',
    }}

    it { should contain_class('wordpress_app::database_profile') }
  end
end
