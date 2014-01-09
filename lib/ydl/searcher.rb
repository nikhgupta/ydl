class Ydl::Searcher
  include Ydl::Helpers

  attr_accessor :options, :keywords
  attr_reader   :filters, :found, :matches

  def initialize keywords = [], options = {}
    self.keywords = keywords
    self.filters  = options
    @options      = options
    @found, @query, @matches = nil, nil, []
  end

  # Create filter groups such that any filter matching with `prominent` group
  # will return the search results, right away. Otherwise, the searches will
  # be filtered down (narrowed) based on the given filters.
  #
  # NOTE: make sure extra filter names, like 'limit', does not coincide with
  # column names in the table.
  #
  def filters= options = {}
    prominent = [ :eid, :url ]
    narrowing = options.keys & Ydl::Videos.columns - prominent
    @filters  = { prominent: prominent, narrowing: narrowing }
  end

  # Run the given search and return the results, so obtained.
  #
  def run
    self.prominence!
    return self.send_results if @query.any?

    self.fuzzy_match
    self.apply_narrowing_filters
    self.apply_limit
    self.load_and_sort_by_matches
    self.send_results
  end

  # If an exact match is intended, return the matching videos from the db.
  #
  def prominence!
    @filters[:prominent].each do |filter|
      @query = Ydl::Videos.where(filter => @options[filter])
      return @query if @query.any?
    end
  end

  # if the user has supplied keywords, use the fuzz ball, and add
  # a percentage column for the matches, at the same time
  #
  # get the matching video's data from the database, otherwise if no match
  # was found, match against the whole database.
  #
  def fuzzy_match
    return unless @keywords.any?

    @matches = fuzz_ball.load.find @keywords.join(" "), @options[:limit]
    @query   = Ydl::Videos
    return if @matches.empty?

    # @matches.map! do |match|
    #   match.push (match[1]/match[2].to_f * 100).to_i
    # end if @matches.any?

    @query = Ydl::Videos.with_pk_in(@matches.map(&:first))
  end

  # now narrow down the matched results using supplied filters
  #
  def apply_narrowing_filters
    @filters[:narrowing].each do |filter|
      @query = @query.where(filter => @options[filter])
    end
    @query
  end

  # now, apply the limit for the number of returned results.
  #
  def apply_limit
    @query = @query.limit(@options[:limit])
  end

  def load_and_sort_by_matches
    @found = @query.all.sort_by do |video|
      match = @matches.detect{|data| data[0] == video.pk}
      video[:score] = self.class.get_score @keywords, match, video
    end.reverse
  end

  def send_results
    found = @found || @query.all
    [ found, @matches, @query ]
  end

  def self.get_score keywords, match, video
    score, total = match[1, 2] rescue [0, 100]
    density = video.nice_title.split(" ") & keywords
    score += 7 * density.count
    # total += 07 * keywords.count
    # (score/total.to_f * 100).to_i
  end

end
