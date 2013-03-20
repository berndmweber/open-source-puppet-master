require 'puppetlabs_spec_helper/module_spec_helper'

def verify_template(subject, title, expected_lines)
  content = subject.resource('file', title).send(:parameters)[:content]
  expected_lines.each do |line|
    content.should match(line)
  end
end