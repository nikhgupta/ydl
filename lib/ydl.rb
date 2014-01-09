# require 'pry'
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

  def self.progressbar start, total, options = {}
    return nil if options[:piped] || options[:verbose]
    start = start.count rescue start
    total = total.count rescue total
    ProgressBar.create({
      starting_at: start, total: total,
      title: "Completed", format: "%a | %b>>%i | %c/%C %t"
    })
  end

  def self.prepare_url_list_from(lists = [])
    return if !lists || lists.empty?
    # populate the list of urls from files and urls supplied to the command.
    lists.map do |list|
      (File.readable?(list) ? File.readlines(list): [ list ]) rescue []
    end.flatten.map(&:strip).uniq
  end

  # insert or update video(s) in the database, and display the progress.
  #
  def self.feed_and_display_progress_for urls, existing, options = {}
    progress = self.progressbar existing, urls, options
    pending  = urls - existing
    verbose  = options[:verbose]

    data = Videos.feed_on_multiple(pending, verbose) do |url, meta|
      case
      when progress then progress.increment
      when meta then self.debug "Found metadata for: #{url}"
      else self.warn "Could not found metadata for: #{url}"
      end
    end

    data.reject{|url, meta| meta.nil?}.keys
  end

  def self.download_and_display_progress_for(urls = [], verbose)
    Ydl::Videos.pending.where(url: urls).map do |video|
      Ydl.delegator.output = verbose
      Ydl.debug "Downloading video: #{video.nice_title}\nThis may take a while.."
      response = video.download

      case
      when response[:file] then Ydl.debug "Downloaded to: #{video.file_path}"
      when verbose && response[:error] then Ydl.warn ":\n"+ response[:output]
      when response[:error] then Ydl.warn response[:error]
      else Ydl.debug ":\n" + response[:output]
      end

      video if response
    end.compact
  end

  def self.display_search_results matched = []
    matched.each do |vid|
      # TODO: convert the following to methods
      status = (vid.completed ? "C" : "P")
      file_path = vid.file_path.gsub(ENV['HOME'], '~') if vid.completed

      message  = "#{"%3d" % vid[:score]} pts : [#{status}] : #{vid.nice_title}"
      message += "        : #{file_path}" if file_path

      puts message
    end
  end

  def self.debug message
    message = "[ DEBUG ] -- #{message}"
    puts message
  end

  def self.warn message
    message = "[WARNING] -- #{message}"
    puts message
  end
end

# require internals
require "ydl/cli"
require "ydl/schema"
require "ydl/videos"
require "ydl/version"
require "ydl/searcher"
require "ydl/delegator"
require "ydl/fuzz_ball"
require "ydl/house_keeper"

class String
  # Sanitize a given string and strip any illegal characters, and downcase it.
  #
  def simple_sanitize(delimiter = " ")
    fn = self.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
    fn.map! { |s| s.gsub /[^a-z0-9\-\']+/i, delimiter }
    fn.join(".").downcase.strip
  end
end
