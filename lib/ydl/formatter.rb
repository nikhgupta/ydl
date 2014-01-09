# Helper methods that perform a certain function and then,
# display the progress or output on the terminal.
#
# These methods are to be used within Ydl::CLI class.
module Ydl::Formatter
  include Ydl::Helpers

  # Add the given videos and display their progress on the CLI using a progress
  # bar.
  #
  def add_videos_and_display_progress urls, existing, options = {}
    progress = create_progressbar existing, urls, options
    pending  = urls - existing
    verbose  = options[:verbose]

    data = Ydl::Videos.feed_on_multiple(pending, verbose) do |url, meta|
      case
      when progress then progress.increment
      when meta then success "Found metadata for: #{url}"
      else warning "Could not found metadata for: #{url}"
      end
    end

    data.reject{|url, meta| meta.nil?}.keys
  end

  # Download the given videos and display their progress on the CLI.
  #
  def download_videos_and_display_progress urls = [], verbose = false
    Ydl::Videos.pending.where(url: urls).all.select do |video|
      delegator.output = verbose
      info "Downloading video: #{video.nice_title}"
      info "This may take a while.."
      response = video.download

      case
      when response[:file]  then success "Downloaded to: #{video.file_path}"
      when verbose          then response[:output]
      when response[:error] then warning response[:error]
      end

      video.completed
    end
  end

  # Search for a keyword and display the given results.
  #
  def display_search_results matched = []
    matched.each do |vid|
      status = (vid.completed ? "C" : "P")
      file_path = vid.file_path.gsub(ENV['HOME'], '~') if vid.completed

      success vid.nice_title, "#{"%3d" % vid[:score]}pts. [#{status}]"
      info file_path, "" if file_path
    end
  end

  private

  def success message, status = "SUCCESS" #:nodoc:#
    say status, message, :green
  end

  def info message, status = "INFO" #:nodoc:#
    say status, message, :cyan
  end

  def debug message, status = "DEBUG" #:nodoc:#
    say status, message, :magenta
  end

  def warning message, status = "WARNING" #:nodoc:#
    say status, message, :yellow
  end

  def say status, message, color = :green
    @shell ||= Thor::Shell::Color.new
    @shell.say_status status, message, color
  end
end
