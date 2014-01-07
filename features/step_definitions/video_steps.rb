# FIXME: video files were downloaded in test run of feed!
# FIXME: sequel reload is required by tests to pick up changes!
When(/^(?:|the )database is reloaded$/) do
  Ydl::Videos::Data.reload!
end

Given(/^I want to pipe the output of (?:this |next )command$/) do
  @extra_options ||= ""
  @extra_options  += " --piped"
end

Given(/^I want to see the output generated by youtube-dl$/) do
  @extra_options ||= ""
  @extra_options  += " --show-output"
end

When(/^I add (?:a )videos? (?:named|with url) "(.*?)"$/) do |list|
  @urls = list.split(",").map{ |name| test_helper_get_video_url(name) }
  command = "feed #{@urls.join(" ")} #{@extra_options}"
  step "I run `ydl #{command}`"
  step 'database is reloaded'
end

Then(/^the output should contain (?:the )urls? for the above videos?$/) do
  @urls.each { |url| step "the output should contain \"#{url}\"" }
end

Then(/cache file with metadata for the videos? should( not)? exist$/) do |negate|
  @urls.each do |url|
    result = File.file? Ydl::Wrapper.metadata_file_for(url)
    expected = !negate
    expect(result).to eq(expected)
  end
end

Then(/^the database file for fuzzy matching of videos should( not)? exist$/) do |negate|
  result = File.file? File.join(Ydl::CONFIG.directory, "videos.trigrams")
  expected = !negate
  expect(result).to eq(expected)
end

Then(/records? for the videos? should( not)? exist in the database$/) do |negate|
  @urls.each do |url|
    json_file  = Ydl::Wrapper.metadata_file_for(url)
    record     = Ydl::Videos::Data.first url: url
    if negate
      expect(record).to be_nil
      expect(File).not_to exist(json_file)
    else
      expect(record).not_to be_nil

      result   = JSON.parse(record.raw_data)
      expected = JSON.parse(File.read(json_file))
      expect(result).to eq(expected)
    end
  end
end
