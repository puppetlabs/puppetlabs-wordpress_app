require 'puppetlabs_spec_helper/module_spec_helper'


RSpec.configure do |c|
  c.before(:each) do
    Puppet[:app_management] = true
  end
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end
