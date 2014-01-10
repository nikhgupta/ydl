Feature: Search Videos
	In order to find out videos using keywords and other parameters
	As a user
	I would like to be able to search videos from given filters

    Background:
        Given I have initialized Ydl on this system

	@slow_process
	Scenario: Keyword Search
		When  I add videos named "phir se; aur ho; tum ho; hawa hawa"
		Then  the output should contain "Added 4 video"
		When  I run `ydl search hawa`
		Then  the output should contain "hawa hawa"
		When  I run `ydl search kawa`
		Then  the output should match /pts.*\[P.*\].*hawa\s*hawa/
		And   the output should not match /\[C.*\].*hawa\s*hawa/

	Scenario: Keyword Search
		Given I have added videos named "phir se; aur ho; tum ho; hawa hawa"
		When  I run `ydl search hawa`
		Then  the output should contain "hawa hawa"
		When  I run `ydl search kawa`
		Then  the output should contain "hawa hawa"
