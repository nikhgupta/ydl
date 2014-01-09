require 'time'
require 'date'
require 'json'
require 'digest/md5'

class Ydl::Videos < Sequel::Model
  include Ydl::Helpers

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
    delegator.capture = true
    output = delegator.run "#{self.url} -iwco '#{classifier}' --restrict-filenames --no-playlist"

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

  class << self
    include Ydl::Helpers

    # Reload the database for this Sequel instance.
    #
    def reload!
      self.set_dataset Sequel.connect("sqlite://#{Ydl::DB_FILE}")[:videos]
    end

    # Retrieve records with primary key that exist in the given array.
    #
    def with_pk_in ids
      self.where(self.primary_key_hash(ids))
    end

    # Insert or update a video in the database.
    #
    def upsert video
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
    def where_url_in(urls = [], conditions = {})
      conditions.merge!(url: urls) if urls.any?
      self.where(conditions).all
    end

    def already_added_urls_in(urls = [], conditions = {})
      self.where_url_in(urls, conditions).map(&:url)
    end

    # Extract metadata information for video(s) with given URLs,
    # add them to database, and iterate over them inside a block.
    #
    def feed_on_multiple(urls = [], verbose = false, &block)
      data    = {}
      urls    = [ urls ].flatten

      # capture information received from youtube-dl as json.
      urls.each do |url|
        meta = self.feed_on url, verbose
        yield(url, meta) if block_given?
        data[url] = meta
      end

      fuzz_ball.prepare
      data
    end

    # Extract metadata info for a single video and add it to the database.
    #
    def feed_on url, verbose = false
      # set options for the next delegation
      delegator.output = verbose
      meta = delegator.extract_metadata_for_video url
      return unless meta

      # Convert to a nicer format for readily database insert/update.
      # Raw data is made available within this format.
      meta = prepare_metadata url, meta

      # insert the meta data in the database
      self.upsert meta

      # return the meta data
      meta
    end

    private

    # prepare metadata for database storage
    def prepare_metadata url, meta
      prepare_data_from_existing_metadata(meta).merge({
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

    def prepare_stats_from_metadata meta
      format = meta["format"].match(/\s*(\d+)\s*-\s*(\d+)x(\d+)\s*$/)
      format_id, width, height = format[1,3].map(&:to_i) rescue [0, 0, 0]
      data = { format: format_id, width: width, height: height }
    end

    def prepare_data_from_existing_metadata meta
      data = prepare_stats_from_metadata(meta)

      %w[duration age_limit view_count playlist_index].each do |key|
        data[key.to_sym] = meta[key].to_i
      end

      %w[playlist uploader uploader_id thumbnail description].each do |key|
        data[key.to_sym] = meta[key]
      end

      data
    end

  end

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
