@slow_process
Feature: Add videos to the database
	In order to readily search and download videos
	As a user
	I would like to be able to tell the videos that I want tracked

	Background:
		Given I have initialized Ydl on this system

	Scenario: Single video by URL without piping support
		When  I add a video named "phir se"
		Then  the output should match /Adding.*Completed.*Added/
		And   the output should contain "Adding 1 video"
		And   the output should contain "Completed: |="
		And   the output should contain "Added 1 video"
		And   a cache file with metadata for the video should exist
		And   the database file for fuzzy matching of videos should exist
		And   a record for the video should exist in the database

	Scenario: Adding multiple videos
		When  I add videos named "phir se; aur ho; tum ho"
		Then  the output should contain "Adding 3 video"
		And   the output should contain "Completed: |="
		And   the output should contain "Added 3 video"
		And   cache files with metadata for the videos should exist
		And   records for the videos should exist in the database

	Scenario: Video with an error
		When  I add a video with url "http://?"
		Then  the output should contain "Discarded 1 video"
		And   a cache file with metadata for the video should not exist
		And   a record for the video should not exist in the database

	Scenario: With piping support
		Given I want to pipe the output of next command
		When  I add a video named "phir se"
		Then  the output should contain the url for the above video
		When  I add a video with url "http://?"
		Then  the output should contain "[WARNING]"

	# NOTE: implies --piped
	Scenario: Without suppressing output from youtube-dl
		Given I want to see the output generated by youtube-dl
		When  I add a video named "phir se"
		Then  the output should contain the url for the above video
		When  I add a video with url "http://youtube.com"
		Then  the output should contain "ERROR: Unsupported URL"
		And   the output should contain "Extracting information"
