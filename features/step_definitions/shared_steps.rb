Given(/^I am using a clean system$/) do
  # remove everything in the configuration directory, but
  # leave the metadata cache available to speed up our tests.
  files = [ "database.db", "videos.trigrams", "conf.yml"]
  files.each do |file|
    file_path = File.join(Ydl::CONFIG.directory, file)
    FileUtils.rm_f file_path if File.exists? file_path
  end
end

When /^I close the stdin stream$/ do
  @interactive.stdin.close()
end
