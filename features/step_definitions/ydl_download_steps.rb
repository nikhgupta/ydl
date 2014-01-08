Given(/^I have downloaded video named "(.*?)"$/) do |list|
  step "I download videos named \"#{list}\""
end

When(/^I download (?:|a |the )videos? (?:|named|with url) "(.*?)"$/) do |list|
  @urls = list.split(";").map{|name| test_helper_get_video_url name}
  step "I run `ydl download '#{@urls.join("' '")}'`"
  step "database is reloaded"
end

Then(/downloaded video files? should exist$/) do
  @urls.each do |url|
    video = Ydl::Videos::Data.where(url: url).first
    file  = video.file_path.to_s
    expect(File).to exist(file)
  end
end

Then(/videos? should be marked as downloaded in the database$/) do
  @urls.each do |url|
    result = Ydl::Videos::Data.completed.where(url: url).any?
    expect(result).to be_true
  end
end

