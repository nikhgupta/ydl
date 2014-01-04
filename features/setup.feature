Feature: Initialize Ydl
    In order to know the preferences of the user and use them before performing actions
    I would like to ask the user about such preferences and store them somewhere

    # TODO: Test the update and path detection for youtube-dl!
    Scenario: Initialize Ydl without updating youtube-dl
        Given I am using a clean system
        When  I initialize Ydl on this system
        Then  the output should contain "Welcome"
        And   the output should contain "default: <current-directory>"
        And   the output should contain "download the playlist"
        And   the output should contain "initial house-keeping"
        And   the configuration file should exist
        And   the preference for "classifier" should exist
        And   the preference for "download_path" should match "tmp/aruba/videos"
        And   the preference for "allow_playlists" should be ""
