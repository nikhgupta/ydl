require 'thor'

# Features to be implemented
# ==========================
#
# # Statistics
# # Tag searches
# # Series Finder
# # Duplicate Finder
# # Multiple download queues
# # Doownload Folder Organizer
# # Tagged based Download Queues
# # Tagged based Download Queues
# # Better Search Results/Reports
# # Priority based Download Queues
# # Search based tag and priority assignment
# # Tags and priority assignment, when feeding

# Features Completed
# ==================
#
# # Initial Setup
# # Updating of youtube-dl program.
# # Adding given urls to the video database.
# # Fuzzy searching the video database.

module Ydl
  # Class that deals with the CLI interface.
  #
  class CLI < Thor

    def initialize *args
      super

      # Raise an error unless Ydl has been initialized or the task was not found.
      # FIXME: use dynamic methods, instead!
      subcommand    = args[2][:current_command].name.downcase.to_sym
      safe_commands = [:init, :help]
      available     = [:update, :feed, :search]
      return if safe_commands.include? subcommand

      # err out with usage if Ydl has not been initialized
      unless Ydl::HouseKeeper.initialized?
        error! "You must run 'ydl init' first!", true
      end

      # err out with usage if an unknown command was requested
      unless available.include?(subcommand)
        error! "Command with name '#{subcommand}' not found!", true
      end
    end

    desc 'help', "display the help message for Ydl"
    def help tip = true
      print "Available "
      super()
      puts "Tip: You must run `ydl init` before you can run other commands." if tip
    end

    # Initialize Ydl on the user's machine, and update youtube-dl, as well.
    #
    # At the moment, no checks are performed to ensure that Ydl is compatible
    # with the given machine, but in the future, it will be so.
    #
    desc 'init', "initialize youtube-dl and companion on this system."
    method_option :update, type: :boolean, default: true,
      desc: "Whether to update 'youtube-dl' program?"
    def init
      # hire a new housekeeper
      house_keeper = Ydl::HouseKeeper.new
      settings     = {}

      # greet the owner.
      puts "Welcome to YDL. The Youtube-DL companion!"
      puts "I would love to assist you in your quest, but first, let me ask you:"
      puts

      # which room should I use?
      question  = "Where should I download the videos? (Give me a folder!)\n"
      question += "Note that, this directory will be created, if it does not exist!\n"
      question += "[default: <current-directory>] "
      settings[:download_path]   = File.expand_path ask(question).strip

      # should I bring the party home?
      question  = "Should I, also, download the playlist associated with a video? [no]"
      settings[:allow_playlists] = yes? question

      # oh, yes! I am organized.
      # FIXME: really needed?
      settings[:classifier]      = "{:extractor}/{:title}-{:id}"

      puts
      if house_keeper.compatible?
        # let the owner know, what mischief we are upto :)
        puts "Alright! That's it :)"
        puts "I will, now, do the initial house-keeping for you."

        # find the path to the youtube-dl program
        begin
          Ydl::Wrapper.path
        rescue RuntimeError
          puts "Seems like this is not my brightest day.. :("
          puts "I was unable to find a valid path to the youtube-dl program on your machine."
          question = "Can you tell me where it is located?"
          options[:youtube_dl_path] = File.expand_path(ask question).strip
        end

        # enough talk! get to work.
        house_keeper.run_setup settings
        house_keeper.upgrade! if options[:update]
      else
        # saying goodbyes. :(
        puts "Unfortunately, I am incompatible with your system."
        puts "I am not sure how that happened."
        puts "All I know is that I need to throw myself out."
      end
    end

    # TODO: and, maybe the companion, itself?
    desc 'update', "update youtube-dl on this system."
    def update
      house_keeper = Ydl::HouseKeeper.new
      house_keeper.upgrade!
    end

    desc 'feed [PATH1] [PATH2] [URL]..', "add videos from the given files and supplied urls"
    method_option :force, type: :boolean, default: false,
      desc: "Forcefully, refresh new information for videos already in the database."
    def feed *paths
      urls, added = [], 0

      # populate the list of urls from files and urls supplied to the command.
      paths.each do |path|
        if File.readable?(path)
          urls |= (File.readlines(path).map(&:strip) rescue [])
        else # elsif path.url?
          urls.push path
        end
      end

      # insert or update video(s) in the database.
      Ydl::Videos.iterate_on_metadata_for(urls, options[:force]) do |url, meta|
        if meta
          Ydl.debug "Found metadata for: #{url}"
          Ydl::Videos::Data.upsert meta
          added += 1
        else
          Ydl.warn "No metadata could be found for: #{url}"
        end
      end
      puts "Added #{added} video(s)."

      # re-generate our fuzzy match database.
      puts "Generating fuzzy match database.."
      Ydl::FuzzBall.prepare
    end

    desc 'search [KEYWORDS]', "search and display videos with the given keywords"
    method_option :eid, type: :string, desc: "return videos matching the given video (extractor) ID"
    method_option :extractor, type: :string, desc: "filter down the matches based on the given extractor"
    method_option :url, type: :string, desc: "return videos matching the given video url"
    method_option :limit, type: :numeric, default: 10,
      desc: "limit the number of matching results returned by this command (default: 10)"
    def search *keywords
      matched = Videos.search keywords, options
      puts matched.inspect
    end

    default_task :help

    no_tasks {
      private

      def error! message, show_usage = false
        puts "Error Occurred: #{message}\n\n"
        invoke :help, [false] if show_usage
        exit(128)
      end
    }
  end
end
