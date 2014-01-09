require 'fileutils'

# Helper methods to be used through out Ydl module.
#
module Ydl::Helpers

  # Call the delegator, i.e. the youtube-dl program.
  #
  def delegator
    Ydl::Delegator.instance
  end

  # Call the Fuzzy match database, i.e. Blurrily
  #
  def fuzz_ball
    Ydl::FuzzBall
  end

  # Check whether Ydl has been initialized, already?
  #
  def initialized?
    File.exists?(Ydl::CONFIG.path) && !Ydl::CONFIG[:download_path].empty?
  end

  # Setup Ydl with the given options.
  #
  def setup_ydl! options = {}
    # override configuration with given options
    options.each { |key, value| Ydl::CONFIG[key] = value }

    # make sure that the download directory exists
    FileUtils.mkdir_p options[:download_path]

    # TODO: run Sequel Migrations.
  end

  # Upgrade Ydl and Youtube-DL on this machine.
  #
  # FIXME: At the moment, it only updates Youtube-DL.
  #
  def upgrade!
    info "Updating youtube-dl to the latest version.."
    delegator.update

    debug "Preparing fuzzy match database.."
    fuzz_ball.prepare
  end

  # Path to the file containing the metadata information for the given url.
  #
  def metadata_file_for url
    File.join(Ydl::CONFIG.directory, "metadata", url.md5ify + ".info.json")
  end

  # Create a new progress bar.
  #
  def create_progressbar start, total, options = {}
    return nil if options[:piped] || options[:verbose]
    start = start.count rescue start
    total = total.count rescue total
    ProgressBar.create({
      starting_at: start, total: total,
      title: "Completed", format: "%a | %b>>%i | %c/%C %t"
    })
  end

  # Prepare a list of urls from the given arguments.
  # An argument, here, can be an individual url or a file with a list of urls.
  # This method is to be used with Thor's tasks.
  #
  def prepare_list_of_urls_from_arguments(args = [])
    return if !args || args.empty?
    # populate the list of urls from files and urls supplied to the command.
    args.map do |list|
      (File.readable?(list) ? File.readlines(list): [ list ]) rescue []
    end.flatten.map(&:strip).uniq
  end

end
