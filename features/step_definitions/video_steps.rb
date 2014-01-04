When(/^(?:|the )database is reloaded$/) do
  # FIXME: data reload is required for tests to perform!
  Ydl::Videos::Data.reload!
end

When(/^I add video for the songs?: "([^"]*)"$/) do |names|
  @urls = names.split(",").map{ |name| test_helper_get_video_url(name) }
  @urls.each { |url| step "I run `ydl feed #{url}`" }
  step 'database is reloaded'
end

Then(/^the database file for fuzzy matching of videos should exist$/) do
  result = File.file? File.join(Ydl::CONFIG.directory, "videos.trigrams")
  expect(result).to be_true
end

Then(/^the corresponding records? should exist in the database$/) do
  @urls.each do |url|
    json_cache = JSON.parse(File.read(Ydl::Wrapper.metadata_file_for(url)))
    record     = Ydl::Videos::Data.first url: url
    expect(record && JSON.parse(record[:raw_data]) == json_cache).to be_true
  end
end
