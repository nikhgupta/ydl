Feature: Downloading videos

	Background:
		Given I have initialized Ydl on this system

	@downloads
	Scenario: Download a video
		When  I download video named "smallest"
		Then  the output should contain "Adding 1 video"
		And   the output should contain "Downloading 1 video"
		And   the output should contain "youtube's smallest video"
		And   the output should contain "Downloaded 1 video"
		And   a record for the video should exist in the database
		And   the downloaded video file should exist
		And   the video should be marked as downloaded in the database

	@downloads
	Scenario: Download multiple videos
		When  I download videos named "smallest; smallest"
		Then  the output should contain "Adding 2 video"
		And   the output should contain "Downloading 2 video"
		And   the output should contain "Downloaded 1 video"
