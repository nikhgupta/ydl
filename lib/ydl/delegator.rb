require 'singleton'
require 'digest/md5'

module Ydl
  class Delegator

    include Singleton

    attr_accessor :args, :switches, :options, :path, :output, :capture

    def initialize
      self.detect_program_path
      self.reset_for_next_command
    end

    # Path to the youtube-dl binary.
    # TODO: Make path detection platform independent?
    #
    def detect_program_path
      # We first try to detect path using `which` command.
      # If that does not work, we simply ask the user for this path.
      @path = `which youtube-dl`.strip
      @path = Ydl::CONFIG[:youtube_dl_path] if !@path || @path.empty?

      mess = 'youtube-dl was not found in your PATH or the specified location.'
      raise RuntimeError, mess if !@path || @path.empty?
    end

    # Reset args, options and switches for the next command.
    #
    def reset_for_next_command
      self.args, self.switches, self.options = [], [], {}
      self.output, self.capture = false, false
    end
    alias :reset :reset_for_next_command

    # Add new args, switches or options for the next command.
    #
    # To add switches, pass an array.
    # To add options,  pass a  hash.
    # To add args,     pass strings. :)
    #
    def << values
      case values.class.to_s
      when 'Array' then @switches |= values.map(&:to_sym)
      when 'Hash'  then @options.merge!(values)
      else @args |= [ values.to_s ]
      end
      self
    end

    # Run a command using youtube-dl.
    #
    def run
      command  = self.path
      command += " \"#{@args.join("\" \"")}\"" if args.any?
      @switches.each{ |opt| command += " --#{opt.to_s}" }
      @options.each { |opt, val| command += " --#{opt.to_s} \"#{val}\"" }
      command += " 2>&1"
      command += " >/dev/null" unless @capture || @output

      output = `#{command}`.strip
      puts output.gsub(/^/, "          -- ") if @output

      # puts command
      # puts output

      self.reset_for_next_command
      output
    end

    # Path to the file containing the metadata information for the given url.
    #
    def metadata_file_for url
      md5str = (Digest::MD5.new << url.to_s).to_s
      File.join(Ydl::CONFIG.directory, "metadata", md5str + ".info.json")
    end

    # Extract metadata for the video with given url.
    # Note that, this method will cache the json output inside the config dir.
    #
    def extract_metadata_for_video url
      mfile = self.metadata_file_for(url)
      unless File.file? mfile
        self << url
        self << %w[ skip-download write-info-json ignore-errors ]
        self << { output: mfile.gsub(/\.info\.json$/, '') }
        self.run
      end
      JSON.parse File.read(mfile) rescue nil
    end

    def update
      self.reset
      (self << [ "update"]).run
    end

  end
end
