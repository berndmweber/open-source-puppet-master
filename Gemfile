source :rubygems

group :development, :test do
  gem 'rspec-puppet'
  gem 'puppetlabs_spec_helper', :require => false
  gem 'rspec-puppet-augeas', '>=0.2.3'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
