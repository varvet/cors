begin
  require "bundler/gem_tasks"
rescue LoadError
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new('yard:doc') do |task|
    task.options = ['--no-stats']
  end

  desc "Run documentation statistics"
  task 'yard:stats' do
    YARD::CLI::Stats.run('--list-undoc')
  end

  desc "Generate documentation and run documentation statistics"
  task :yard => ['yard:doc', 'yard:stats']
rescue LoadError
  puts "WARN: YARD not available. You may install documentation dependencies via bundler."
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |spec|
  spec.ruby_opts = "-W"
end

desc "Launch a console with the library loaded"
task :console do
  exec "irb", "-Ilib", "-rcors"
end

task :default => :spec
