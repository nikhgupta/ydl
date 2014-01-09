require 'singleton'

# Class that calls the youtube-dl program for custom tasks.
#
class Ydl::Delegator

  include Singleton
  include Ydl::Helpers

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

    @path
  end

  def unknown?
    false if self.detect_program_path rescue true
  end

  # Reset args, options and switches for the next command.
  #
  def reset_for_next_command
    # self.args, self.switches, self.options = [], [], {}
    self.output, self.capture = false, false
  end
  alias :reset :reset_for_next_command

  # Add new args, switches or options for the next command.
  #
  # To add switches, pass an array.
  # To add options,  pass a  hash.
  # To add args,     pass strings. :)
  #
  # def << values
  #   case values.class.to_s
  #   when 'Array' then @switches |= values.map(&:to_sym)
  #   when 'Hash'  then @options.merge!(values)
  #   else @args |= [ values.to_s ]
  #   end
  #   self
  # end

  # Run a command using youtube-dl.
  #
  def run command
    # unless command
    #   command = " \"#{@args.join("\" \"")}\"" if args.any?
    #   @switches.each{ |opt| command += " --#{opt.to_s}" }
    #   @options.each { |opt, val| command += " --#{opt.to_s} \"#{val}\"" }
    # end
    return if command.nil? || command.strip.empty?
    command += " 2>&1"
    command += " >/dev/null" unless @capture || @output

    output = `#{self.path} #{command}`.strip
    puts output.gsub(/^/, "          -- ") if @output

    self.reset_for_next_command
    output
  end

  # Extract metadata for the video with given url.
  # Note that, this method will cache the json output inside the config dir.
  #
  def extract_metadata_for_video url
    mfile = metadata_file_for(url)
    unless File.file? mfile

      # self << url
      # self << %w[ skip-download write-info-json ignore-errors ]
      # self << { output: mfile.gsub(/\.info\.json$/, '') }
      # self.run

      # Run directly:
      command  = "#{url} --skip-download --write-info-json --ignore-errors"
      command += " -o '#{mfile.gsub(/\.info\.json$/, '')}'"
      delegator.run command
    end
    JSON.parse File.read(mfile) rescue nil
  end

  def update
    self.run "--update"
  end

end
