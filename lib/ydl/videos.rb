require 'time'
require 'date'
require 'json'
require 'digest/md5'

module Ydl
  module Videos

    class Data < Sequel::Model
      # tell Sequel to use the given database table
      set_dataset Ydl::DATABASE[:videos]

      # create some scopes
      subset :pending,   completed: 0
      subset :completed, completed: 1

      # reload the database instance
      def self.reload!
        self.set_dataset Sequel.connect("sqlite://#{Ydl::DB_FILE}")[:videos]
      end

      self.dataset_module do

        # Retrieve records with primary key exists in the given array.
        #
        def with_pk_in ids
          self.where(self.model.primary_key_hash(ids))
        end

        # Insert or update a video in the database.
        #
        def upsert video
          self.db.transaction do
            record = self.model.find hash: video[:hash]
            if record
              record.update video
            else
              self.model.create video
            end
          end
        end

        # Mark a video as downloaded.
        #
        # == Parameters ==
        # +id+: ID or hash for the given video.
        #
        def mark_as_downloaded id
          record = self[id]
          record = self.find(hash: id) unless record
          return nil unless record
          record.update completed: 1, downloaded_at: DateTime.now
        end
      end

    end

    # Create a unique hash from the video's metadata.
    #
    def self.hashify_metadata(data)
      (Digest::MD5.new << "#{data["extractor"].downcase}-#{data["id"]}").to_s
    end

    # Download fresh metadata for the given urls, and add them to the database.
    #
    def self.add urls
      iterate_on_metadata_for(urls) do |url, meta|
        Data.upsert meta
      end

      Ydl::FuzzBall.prepare
    end

    # Search the database for videos matching the given keywords.
    #
    # This is done using fuzzy matching and eager loading as much as possible.
    # If you want to grab an instance of `Sequel::SQLite::Dataset` object,
    # add a `query: true` option to `options`.
    #
    def self.search keywords = nil, options = {}
      found, matches = nil, []

      # find the possible filters that the user has passed
      # NOTE: make sure extra filter names, like 'limit', does not coincide with
      # column names in the table.
      prominent_filters  = [:eid, :url]
      narrowing_filters = options.keys & Data.columns - prominent_filters

      # if an exact match is intended, return the matching videos from the db
      prominent_filters.each do |filter|
        found = Data.where(filter => options[filter])
        break if found.any?
      end

      # if the user has supplied keywords, use the fuzz ball, and add
      # a percentage column for the matches, at the same time
      #
      # get the matching video's data from the database, otherwise if no match
      # was found, match against the whole database.
      if keywords && found.empty?
        fuzz_ball = Ydl::FuzzBall.load
        matches   = fuzz_ball.find keywords, options[:limit]
        matches.map!{ |m| m.push (m[1]/m[2].to_f * 100).to_i  } if matches.any?
        found = matches.empty? ? Data : Data.with_pk_in(matches.map(&:first))
      end

      # now narrow down the matched results using supplied filters
      narrowing_filters.each do |filter|
        found = found.where(filter => options[filter])
      end

      # now, apply the limit for the number of returned results
      found = found.limit(options[:limit])

      # load and sort the results from database, now, if the user does not want
      # an instance of `Sequel::SQLite::Dataset`
      if !options[:query]
        found = found.all

        found = found.sort_by do |video|
          matched, total = matches.detect{|data| data[0] == video.pk}[1,2]
          video[:match_percent] = (matched/total.to_f * 100).to_i
        end.reverse if matches.any?
      end

      # now, just send the results we found with that much patience.
      return [ found, matches ]
    end

    def self.filter_out_existing_videos(urls = [])
      urls -= Data.select(:url).all.map(&:url)
    end

    # Extract metadata information for video(s) with given URLs,
    # and iterate over them inside a block.
    #
    def self.iterate_on_metadata_for(urls = [], &block)
      data    = {}
      urls    = [ urls ].flatten
      count   = urls.count

      # capture information received from youtube-dl as json.
      urls.each_with_index do |url, index|
        meta = Ydl.delegator.extract_metadata_for_video url

        if meta
          # extract video's format and dimensions
          format = meta["format"].match(/\s*(\d+)\s*-\s*(\d+)x(\d+)\s*$/)
          format_id, width, height = format[1,3].map(&:to_i) rescue [0, 0, 0]

          # Convert to a nicer format for readily database insert/update.
          # Raw data is made available within this format.
          meta = {
            eid:            meta["id"],
            hash:           self.hashify_metadata(meta),
            url:            url,
            extractor:      meta["extractor"].downcase,
            short_title:    meta["stitle"],
            full_title:     meta["fulltitle"],
            nice_title:     meta["fulltitle"].simple_sanitize,
            file_path:      nil,
            extension:      meta["ext"],
            description:    meta["description"],
            thumbnail:      meta["thumbnail"],
            uploader:       meta["uploader"],
            uploader_id:    meta["uploader_id"],
            playlist:       meta["playlist"],
            playlist_index: meta["playlist_index"].to_i,
            width:          width,
            height:         height,
            duration:       meta["duration"].to_i,
            age_limit:      meta["age_limit"].to_i,
            view_count:     meta["view_count"].to_i,
            format:         format_id,
            completed:      false,
            active:         true,
            raw_data:       meta.to_json,
            uploaded_on:    (Date.parse(meta["upload_date"]) rescue nil),
            downloaded_at:  nil,
            updated_at:     DateTime.now
          }

          data[url] = meta
        end

        yield(url, meta) if block_given?
      end

      # no need to remove files from /tmp directory, IMO.
      data
    end

  end
end
