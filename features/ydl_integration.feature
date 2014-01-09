@slow_process
Feature: Integration Test ;)

	Background:
		Given I have initialized Ydl on this system
		And   I have added videos named "phir se; hawa hawa; tum ho"
		And   I have downloaded video named "timer"

	Scenario: Adding already added videos
		When  I add a video named "phir se"
		Then  the output should contain "Adding 1 video"
		And   the output should contain "Found 1 existing video"
		And   the output should contain "Added 0 video"

	Scenario: Downloading already downloaded videos
		When  I download a video named "timer"
		Then  the output should contain "Downloading 1 video"
		And   the output should contain "Found 1 existing video"
		And   the output should contain "Downloaded 0 video"

	Scenario: Keyword Search with a downloaded video
		When  I run `ydl search countdown`
		Then  the output should match /\[C.*\].*countdown/
