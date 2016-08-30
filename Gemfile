source 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : ['>= 3.3']
gem 'puppet', puppetversion
gem 'facter', '>= 1.7.0'

group :development, :test do
  gem 'puppetlabs_spec_helper', '>= 1.1.1'
  gem 'puppet-lint', '>= 2.0.0'
  gem 'rspec-puppet', '>= 2.4.0'
end
