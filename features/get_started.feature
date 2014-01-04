Feature: Getting Started and Basics

	To get started, just open the terminal in an empty directory,
	and run `ydl`. You'll be prompted for what to do next.

	Scenario: Tipful help/usage for first timers
		Given I am using a clean system
		When  I run `ydl`
		Then  it should pass with regex:
				"""
				Commands.*Tip.*run.*ydl init
				"""
