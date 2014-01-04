Feature: Error Handling
    In order to know the course of actions when an error occurs
    As a user
    I would like sensible error messages that I will understand

    Scenario: Must be initialized before any other action can be performed
        Given I am using a clean system
        When  I run `ydl search`
        Then  it should fail with regex:
            """
            Error.*run.*ydl init.*Commands
            """

    Scenario: Displays errors when unknown action is requested
      Given I have initialized Ydl on this system
      When  I run `ydl unknown`
      Then  it should fail with regex:
          """
          Error.*not found.*Commands
          """
