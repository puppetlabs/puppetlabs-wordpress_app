require 'spec_helper'
describe 'wordpress_app' do

  context 'with defaults for all parameters' do
    it { should contain_class('wordpress_app') }
  end
end
