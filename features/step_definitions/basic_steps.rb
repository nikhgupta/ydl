Given(/^I have initialized Ydl on this system$/) do
  step "I initialize Ydl on this system"
  step 'the output should contain "Welcome"'
  step 'the output should contain "initial house-keeping"'
  step 'the configuration file should exist'
  step 'the preference for "download_path" should match "tmp/aruba/videos"'
end

When(/^I initialize Ydl on this system$/) do
  step "I am using a clean system"
  step "the configuration file should not exist"
  step "I run `ydl init --no-update` interactively"
  step "I type \"./videos\""
  step "I type \"\""
  step "I close the stdin stream"
end

Then(/^the configuration file should( not)? exist$/) do |negate|
  result = File.file?(Ydl::CONFIG.path)
  expected = !negate
  expect(result).to eq(expected)
end

Then(/^the preference for "([^"]*)" should exist$/) do |key|
  result = Ydl::CONFIG[key.to_sym].to_s
  expect(result).not_to eq("")
end

Then(/^the preference for "([^"]*)" should (?:be|match) "([^"]*)"$/) do |key, value|
  result      = Ydl::CONFIG[key.to_sym].to_s
  expectation = Regexp.new value
  expect(result).to match(expectation)
end
