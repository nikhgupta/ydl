require 'pry'
require 'json'
require 'sequel'
require 'sqlite3'
require 'conjuror'
require 'fileutils'
require 'blurrily/map'
require 'ruby-progressbar'

# SQLite: please, do not load association plugin!
::SEQUEL_NO_ASSOCIATIONS = true

# Ydl is a companion to the Youtube-DL program.
# It enables you to keep track of what videos you are downloading,
# along with their progress, as well as allows you to quickly search
# your local video database using fuzzy matching algorithms.
#
module Ydl
  CONFIG   = Conjuror.new(ENV['ARUBA_TEST'] ? "ydl-test" : "ydl")
  DB_FILE  = File.join(CONFIG.directory, "database.db")
  DATABASE = Sequel.connect("sqlite://#{DB_FILE}")

  def self.delegator
    Delegator.instance
  end
end

# require internals
require "ydl/version"
require "ydl/fuzz_ball"
require "ydl/delegator"
require "ydl/videos"
require "ydl/house_keeper"
require "ydl/cli"

class String
  # Sanitize a given string and strip any illegal characters, and downcase it.
  #
  def simple_sanitize(delimiter = " ")
    fn = self.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, delimiter }
    fn.join(".").downcase.strip
  end
end
