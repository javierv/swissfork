require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |task, args|
  task.exclude_pattern = "spec/swissfork/performance/*.rb"
end
