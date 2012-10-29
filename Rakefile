require "bundler/setup"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |spec|
  spec.ruby_opts = "-W"
end

task :console do
  exec "irb", "-Ilib", "-rcors"
end

task :default => :spec
