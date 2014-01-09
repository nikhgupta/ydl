# require 'pry'
require 'json'
require 'sequel'
require 'sqlite3'
require 'conjuror'
require 'fileutils'
require 'blurrily/map'
require 'ruby-progressbar'

# Ydl is a companion to the Youtube-DL program.
# It enables you to keep track of what videos you are downloading,
# along with their progress, as well as allows you to quickly search
# your local video database using fuzzy matching algorithms.
#
module Ydl; end
SEQUEL_NO_ASSOCIATIONS = true # SQLite: please, do not load association plugin!
Ydl::CONFIG   = Conjuror.new(ENV['ARUBA_TEST'] ? "ydl-test" : "ydl")
Ydl::DB_FILE  = File.join(Ydl::CONFIG.directory, "database.db")
Ydl::DATABASE = Sequel.connect("sqlite://#{Ydl::DB_FILE}")

# require internals
require "ydl/version"
require "ydl/extensions"
require "ydl/helpers"
require "ydl/formatter"
require "ydl/schema"
require "ydl/delegator"
require "ydl/fuzz_ball"
require "ydl/videos"
require "ydl/searcher"
require "ydl/cli"
