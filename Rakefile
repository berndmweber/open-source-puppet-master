all_tests = [
  'puppet',
  ]

all_tests.each do |test|
  import "modules/#{test}/Rakefile"
end

task :test_all do
  all_tests.each do |test|
    puts test
    Dir.chdir "modules/#{test}"
    Rake::Task[:spec].invoke
    Rake::Task[:spec].reenable
    Rake::Task[:spec_prep].reenable
    Rake::Task[:spec_standalone].reenable
    Rake::Task[:spec_clean].reenable
    Dir.chdir "../.."
  end
  puts "Done"
end

task :test_all_html do
  all_tests.each do |test|
    puts test
    Dir.chdir "modules/#{test}"
    Rake::Task[:spec_html].invoke
    Rake::Task[:spec_html].reenable
    Rake::Task[:spec_prep].reenable
    Rake::Task[:spec_html_standalone].reenable
    Rake::Task[:spec_clean].reenable
    Dir.chdir "../.."
  end
  puts "Done"
end

task :default => :test_all
