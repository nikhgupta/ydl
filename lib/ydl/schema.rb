# videos
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
