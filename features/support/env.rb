# require some libraries
require 'json'
require 'digest/md5'

# setup environment variable that notifies Ydl that we are testing it ;)
ENV['ARUBA_TEST'] = "true"

# load our gem
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'ydl'

# remove any configuration or metadata before the test suite starts.
# FileUtils.rm_rf Ydl::CONFIG.directory

# load the testing framework
# TODO: tests should share aruba's process: http://git.io/b5gkGQ
require 'aruba/cucumber'

# allow upto 10 seconds for slow requests
Before('@slow_process') do
  @aruba_timeout_seconds = 10
  @aruba_io_wait_seconds = 10
end

# allow upto 10 seconds for slow requests
Before('@downloads') do
  @aruba_timeout_seconds = 60
  @aruba_io_wait_seconds = 60
end


# allow upto an hour for pry sessions
Before('@pry') do
  @aruba_timeout_seconds = 3600
  @aruba_io_wait_seconds = 3600
end

After do |scenario|
  # Tell Cucumber to quit after this scenario is done - if it failed.
  Cucumber.wants_to_quit = true if scenario.failed?

  # clean up configuration and database
  FileUtils.rm_f File.join(Ydl::CONFIG.directory, "conf.yml")
  FileUtils.rm_f File.join(Ydl::CONFIG.directory, "database.db")
end

# Global Teardown
at_exit do

end
