require 'time'
require 'date'
require 'json'
require 'digest/md5'

module Ydl
  class Videos < Sequel::Model

    # tell Sequel to use the given database table
    set_dataset Ydl::DATABASE[:videos]

    # create some scopes
    subset :pending,   completed: 0
    subset :completed, completed: 1

    # Download the current video.
    # TODO: Probably: http://bit.ly/1lQpQyF to capture the download progress??
    #
    def download
      classifier = File.join(Ydl::CONFIG[:download_path], replace_ydl_classifiers)

      # Ydl.delegator << self.url
      # Ydl.delegator << %w[ ignore-errors no-overwrites continue restrict-filenames no-playlist ]
      # Ydl.delegator << { output: classifier}

      # run directly:
      Ydl.delegator.capture = true
      output = Ydl.delegator.run "#{self.url} -iwco '#{classifier}' --restrict-filenames --no-playlist"

      error  = output.match(/^ERROR:\s*(.*?)$/)[1] rescue nil
      file   = output.match(/^\[.*?\]\s*Destination:\s*(.*?)$/)[1] rescue nil
      error  = "Could not find desination" unless error || file
      return { output: output, error: error } if error

      self.mark_as_downloaded file_path: file
      { file: file, output: output, error: error}
    end

    # Mark the current video as downloaded while updating the given parameters.
    #
    def mark_as_downloaded params = {}
      params.merge! completed: 1, downloaded_at: DateTime.now
      self.update params
    end

    # Reload the database for this Sequel instance.
    #
    def self.reload!
      self.set_dataset Sequel.connect("sqlite://#{Ydl::DB_FILE}")[:videos]
    end

    # Retrieve records with primary key that exist in the given array.
    #
    def self.with_pk_in ids
      self.where(self.primary_key_hash(ids))
    end

    # Insert or update a video in the database.
    #
    def self.upsert video
      self.db.transaction do
        record = self.find url: video[:url]
        if record
          record.update video
        else
          self.create video
        end
      end
    end

    # Find all videos from database that have urls in a given list.
    #
    def self.where_url_in(urls = [], conditions = {})
      conditions.merge!(url: urls) if urls.any?
      self.where(conditions).all
    end

    # Extract metadata information for video(s) with given URLs,
    # add them to database, and iterate over them inside a block.
    #
    def self.feed_on_multiple(urls = [], verbose = false, &block)
      data    = {}
      urls    = [ urls ].flatten

      # capture information received from youtube-dl as json.
      urls.each do |url|
        meta = self.feed_on url, verbose
        yield(url, meta) if block_given?
        data[url] = meta
      end

      Ydl::FuzzBall.prepare
      data
    end

    # Extract metadata info for a single video and add it to the database.
    #
    def self.feed_on url, verbose = false
      # set options for the next delegation
      Ydl.delegator.output = verbose
      meta = Ydl.delegator.extract_metadata_for_video url
      return unless meta

      # Convert to a nicer format for readily database insert/update.
      # Raw data is made available within this format.
      meta = prepare_metadata url, meta

      # insert the meta data in the database
      self.upsert meta

      # return the meta data
      meta
    end

    # Search the database for videos matching the given keywords.
    #
    # This is done using fuzzy matching and eager loading as much as possible.
    # If you want to grab an instance of `Sequel::SQLite::Dataset` object,
    # add a `query: true` option to `options`.
    #
    def self.fuzzy_search keywords = [], options = {}
      found, matches = nil, []

      # find the possible filters that the user has passed
      # NOTE: make sure extra filter names, like 'limit', does not coincide with
      # column names in the table.
      prominent_filters  = [:eid, :url]
      narrowing_filters = options.keys & self.columns - prominent_filters

      # if an exact match is intended, return the matching videos from the db
      prominent_filters.each do |filter|
        found = self.where(filter => options[filter])
        break if found.any?
      end

      # if the user has supplied keywords, use the fuzz ball, and add
      # a percentage column for the matches, at the same time
      #
      # get the matching video's data from the database, otherwise if no match
      # was found, match against the whole database.
      if keywords.any? && found.empty?
        fuzz_ball = Ydl::FuzzBall.load
        matches   = fuzz_ball.find keywords.join(" "), options[:limit]
        matches.map!{ |m| m.push (m[1]/m[2].to_f * 100).to_i  } if matches.any?
        found = matches.empty? ? self : self.with_pk_in(matches.map(&:first))
      end

      # now narrow down the matched results using supplied filters
      narrowing_filters.each do |filter|
        found = found.where(filter => options[filter])
      end

      # now, apply the limit for the number of returned results, and
      # load and sort the results from database
      found = found.limit(options[:limit]).all
      found = found.sort_by do |video|
        score, total = matches.detect{|data| data[0] == video.pk}[1,2] rescue [0,100]
        density = video.nice_title.split(" ") & keywords
        score = score + 07 * density.count
        video[:score] = score
        # total = 07 * keywords.count
        # video[:score] = (score/total.to_f * 100).to_i
      end.reverse

      # now, just send the results we found with that much patience.
      return [ found, matches ]
    end

    def self.dimensions meta
      format = meta["format"].match(/\s*(\d+)\s*-\s*(\d+)x(\d+)\s*$/)
      format_id, width, height = format[1,3].map(&:to_i) rescue [0, 0, 0]
      { format: format_id, width: width, height: height }
    end

    private_class_method :dimensions

    # prepare metadata for database storage
    def self.prepare_metadata url, meta
      data = dimensions(meta)

      %w[duration age_limit view_count playlist_index].each do |key|
        data[key.to_sym] = meta[key].to_i
      end

      %w[playlist uploader uploader_id thumbnail description].each do |key|
        data[key.to_sym] = meta[key]
      end

      data.merge({
        eid:            meta["id"],
        url:            url,
        extractor:      meta["extractor"].downcase,
        short_title:    meta["stitle"],
        full_title:     meta["fulltitle"],
        nice_title:     meta["fulltitle"].simple_sanitize,
        extension:      meta["ext"],
        raw_data:       meta.to_json,
        uploaded_on:    (Date.parse(meta["upload_date"]) rescue nil),
        updated_at:     DateTime.now
      })
    end

    private_class_method :prepare_metadata

    private

    # TODO: test this method!
    def replace_ydl_classifiers
      str = Ydl::CONFIG[:classifier]
      str = str.gsub("%(width)s", self.width.to_s)
      .gsub("%(height)s", self.height.to_s)
      .gsub("%(duration)s", self.duration.to_s)
      .gsub("%(age_limit)s", self.age_limit.to_s)
    end

  end
end
