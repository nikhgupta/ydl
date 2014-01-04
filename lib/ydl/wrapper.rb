require 'digest/md5'

module Ydl
  module Wrapper

    # Path to the youtube-dl binary.
    #
    # TODO: Make path detection platform independent?
    #
    def self.path
      # We first try to detect path using `which` command.
      # If that does not work, we simply ask the user for this path.
      #
      path = `which youtube-dl`.strip
      path = Ydl::CONFIG[:youtube_dl_path] if !path || path.empty?

      mess = 'youtube-dl was not found in your PATH or the specified location.'
      raise RuntimeError, mess if !path || path.empty?
      path
    end

    # Run a command using youtube-dl.
    #
    def self.run(url = nil, switches = [], options = {})
      command  = self.path + " " + url.to_s
      options.each { |opt, val| command += " --#{opt.to_s} #{val}" }
      switches.each{ |opt| command += " --#{opt}" }
      `#{command}`.strip
    end

    # Path to the file containing the metadata information for the given url.
    #
    def self.metadata_file_for url
      md5str = (Digest::MD5.new << url.to_s).to_s
      File.join(Ydl::CONFIG.directory, "metadata", md5str + ".info.json")
    end

    # Extract metadata for the video with given url.
    # Note that, this method will cache the json output inside the config dir.
    #
    def self.extract_metadata_for_video url
      mfile      = self.metadata_file_for(url)
      unless File.file? mfile
        switches = %w[ skip-download write-info-json ignore-errors ]
        options  = { output: mfile.gsub(/\.info\.json$/, '') }
        output   = self.run url, switches, options
      end
      JSON.parse File.read(mfile) rescue nil
    end

  end
end
