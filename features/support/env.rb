# setup environment variable that notifies Ydl that we are testing it ;)
ENV['ARUBA_TEST'] = "true"

# require some libraries
require 'json'
require 'digest/md5'

# load our gem
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'ydl'

# load the testing framework
require 'aruba/cucumber' # TODO: tests should share aruba's process: http://git.io/b5gkGQ

# allow upto 10 seconds for slow requests
Before('@slow_process') do
  @aruba_timeout_seconds = 30
  @aruba_io_wait_seconds = 30
end

# allow upto an hour for pry sessions
Before('@pry') do
  @aruba_timeout_seconds = 3600
  @aruba_io_wait_seconds = 3600
end
