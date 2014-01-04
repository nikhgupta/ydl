module Ydl
  module FuzzBall

    def self.path
      File.join(Ydl::CONFIG.directory, "videos.trigrams")
    end

    # Load the fuzzy ball in memory.
    #
    def self.load
      Blurrily::Map.load self.path
    end

    # Prepare a fresh fuzzy ball from the database,
    # and, replace the existing one with this new one.
    #
    def self.prepare
      fuzzy = Blurrily::Map.new
      Ydl::Videos::Data.each do |video|
        # Only title and file's name is searched for fuzzy matches.
        # Video's id is, now, not searched fuzzily, which makes sense, as the id
        # need not match partially. Therefore, it is now matched via string
        # matching.
        filename = File.basename(video.url, ".#{video.extension}}")
        keywords = video.nice_title + " " + filename.simple_sanitize.gsub("_", " ")
        fuzzy.put keywords.strip, video.pk # associate the given keywords with the primary key
      end
      fuzzy.save self.path
    end

  end
end
