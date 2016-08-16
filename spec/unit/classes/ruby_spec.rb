require 'spec_helper'

describe 'wordpress_app::ruby', :type => :class do
  context 'with defaults for all parameters' do
    it { should compile }
    it { should contain_class('wordpress_app::ruby') }
  end
end
