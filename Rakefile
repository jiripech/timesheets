# Rakefile

def print_and_flush(str)
    print str
    $stdout.flush
end

task default: [:print_ruby_version, :install_gems, :run]

task :print_ruby_version do
    puts "Using ruby version " + RUBY_VERSION
end

task :install_gems do
    puts "Installing bundler"
    exec('gem install bundler')
    puts "Installing gems from the Gemfile"
    exec('bundle install_gems')
end

task :run do
    require ('app/timesheets')
end