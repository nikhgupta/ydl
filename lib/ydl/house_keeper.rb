module Ydl

  class HouseKeeper

    def self.initialized?
      File.exists?(Ydl::CONFIG.path) && !Ydl::CONFIG[:download_path].empty?
    end

    # TODO: method stub.
    #
    def compatible?; true; end

    # Do the initial house-keeping work.
    #
    def run_setup options = {}

      # override current configuration with the given settings
      override_configuration options

      # make sure that the download directory exists
      FileUtils.mkdir_p options[:download_path]
    end

    # Upgrade Ydl and Youtube-DL on this machine.
    #
    # FIXME: At the moment, it only updates Youtube-DL.
    #
    def upgrade!
      puts "Updating youtube-dl to the latest version.."
      Ydl.delegator.update

      puts "Preparing fuzzy match database.."
      Ydl::FuzzBall.prepare
    end

    private
    # Override the gem's current configuration with the given settings.
    #
    def override_configuration settings = {}
      settings.each { |key, value| Ydl::CONFIG[key] = value }
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
