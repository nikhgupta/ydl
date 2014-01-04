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

      # create the database tables as well
      setup_database_tables
    end

    # Upgrade Ydl and Youtube-DL on this machine.
    #
    # FIXME: At the moment, it only updates Youtube-DL.
    #
    def upgrade!
      puts "Updating youtube-dl to the latest version.."
      Ydl::Wrapper.run nil, [ "update" ]
    end

    private
    # Override the gem's current configuration with the given settings.
    #
    def override_configuration settings = {}
      settings.each { |key, value| Ydl::CONFIG[key] = value }
    end

    # Create database tables, if they do not exist.
    #
    def setup_database_tables
      # create the database table for: videos
      unless Ydl::DATABASE.table_exists? :videos
        Ydl::DATABASE.create_table :videos do
          primary_key :id
          column :eid,            :string
          column :extractor,      :string
          column :hash,           :string, size: 32, index: { unique: true }
          column :url,            :string, null: false
          column :short_title,    :string
          column :full_title,     :string
          column :nice_title,     :string
          column :file_path,      :string
          column :extension,      :string
          column :description,    :string
          column :thumbnail,      :string
          column :uploader,       :string
          column :uploader_id,    :string
          column :playlist,       :string
          column :playlist_index, :integer
          column :width,          :integer
          column :height,         :integer
          column :duration,       :integer
          column :age_limit,      :integer
          column :view_count,     :integer
          column :format,         :integer
          column :completed,      :boolean, default: false
          column :active,         :boolean, default: true
          column :raw_data,       :string,  null: false
          column :uploaded_on,    :date
          column :downloaded_at,  :datetime
          column :updated_at,     :datetime
        end
      end
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
