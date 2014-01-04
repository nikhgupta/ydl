Feature: Add videos to the database
    In order to readily search and download videos
    As a user
    I would like to be able to tell the videos that I want tracked

    @slow_process
    Scenario: Single video by URL
        Given I have initialized Ydl on this system
        When  I add video for the song: "phir se"
        Then  the output should contain "Added 1 video(s)"
        And   the database file for fuzzy matching of videos should exist
        And   the corresponding record should exist in the database
        # And   searching for "" should show the current video
