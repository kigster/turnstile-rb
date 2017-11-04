require "bundler/gem_tasks"
require 'yard'

def shell(*args)
  puts "running: #{args.join(' ')}"
  system(args.join(' '))
end

task :permissions do
  shell('rm -rf pkg/')
  shell('rm -f Gemfile.lock')
  shell("chmod -v o+r,g+r * */* */*/* */*/*/* */*/*/*/* */*/*/*/*/*")
  shell("find . -type d -exec chmod o+x,g+x {} \\;")
end

task :build => :permissions

YARD::Rake::YardocTask.new(:doc) do |t|
  t.files = %w(lib/**/*.rb exe/*.rb - README.md LICENSE)
  t.options.unshift('--title','"Turnstile — Active User Counter"')
  t.after = ->() { exec('open doc/index.html') }
end
