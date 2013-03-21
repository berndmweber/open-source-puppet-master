require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-augeas'

RSpec.configure do |c|
  c.augeas_fixtures = File.join(File.dirname(File.expand_path(__FILE__)), 'fixtures', 'augeas')
end

def verify_template(subject, title, expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  expected_lines.each do |line|
    content.should match(line)
  end
end

def verify_template_not(subject, title, not_expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  not_expected_lines.each do |line|
    content.should_not match(line)
  end
end
