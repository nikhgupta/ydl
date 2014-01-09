# Ydl

The Unofficial [youtube-dl](youtube-dl) Companion :)  
**In heavy development stages..**

## Features Intended:

- **Utilities**:
	- <del>Update youtube-dl and the fuzzy-match database.</del>
	- <del>Fuzzily search the database for matching keywords, and other information.</del>
	- <del>Add a list of urls to the database from given arguments or files.</del>
    - <del>Download a list of urls to the database from given arguments or files.</del>
	- Find videos in a Series.
	- Find duplicate videos across the database, and remove them.
	- Syncronize videos between database and local disk.
	- Organize downloads folder based on the given pattern.
	- Search videos online based on the given keywords.
- **Assign `classifiers`** (e.g. tags, priorities, status, etc.):
	- when adding new videos
	- based on result of current search
- **Search**, **List** and **Download** videos based on (`classifiers`):
	- Tags
	- Priority
	- Extractors
	- Keywords
	- Priority
	- Status, i.e. downloaded, pending, queued, etc.
	- Queues (lists and downloads only)
- All commands will provide **pipeable output**.
- Simple reports for various statistics (for fun).

## Installation

Install it on your machine, like this:

    $ gem install ydl

Note that, `Ydl` needs [youtube-dl](youtube-dl) in order
to work, and currently, is not compatible with Windows OS.

## Usage

Just run `ydl` in your terminal, once you have installed the gem on your
machine.

## TODOs

1. Move `Ydl.delegator.metadata_file_for` method to `Ydl`
2. Learn how to install youtube-dl on travis and enable travis-ci support.
3. Upload small test videos and use them in the tests.
4. Hash of videos should be done on the url itself (think about generic videos).
5. Display video's download progress when downloading.
6. Use a central location to store the video metadata for all users, anonymously?
   - *Benefit*    : That will greatly decrease the time it takes to add videos in db.
   - *Caution*    : Will create a huge amount of database, in my opinion.
   - *Note*       : Fall back to local extraction of json data when service does not work.
   - *Performance*: The service would cache json for future processing.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


  [youtube-dl]: http://rg3.github.io/youtube-dl/
