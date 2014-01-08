Feature: Getting Started and Error Handling

	To get started, just open the terminal in an empty directory,
	and run `ydl`. You'll be prompted for what to do next.

	Scenario: Tipful help/usage for first timers
		When  I run `ydl`
		Then  it should pass with regex:
		"""
		Commands.*Tip.*run.*ydl init
		"""

	Scenario: Must be initialized before any other action can be performed
		When  I run `ydl search`
		Then  it should fail with regex:
		"""
		Error.*run.*ydl init.*Commands
		"""

	# TODO: Test the update and path detection for youtube-dl!
	Scenario: Initialize Ydl without updating youtube-dl
		When  I initialize Ydl on this system
		Then  the output should contain "Welcome"
		And   the output should contain "default: <current-directory>"
		And   the output should contain "download the playlist"
		And   the output should contain "initial house-keeping"
		And   the configuration file should exist
		And   the preference for "classifier" should exist
		And   the preference for "download_path" should match "tmp/aruba/videos"
		And   the preference for "allow_playlists" should be ""

	Scenario: Displays errors when unknown action is requested
		Given I have initialized Ydl on this system
		When  I run `ydl unknown`
		Then  it should fail with regex:
		"""
		Error.*not found.*Commands
		"""
