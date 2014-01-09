module Ydl
  module TestHelpers

      def test_helper_get_video_url name
        case name.strip
        when "phir se"   then "http://www.youtube.com/watch?v=2mWaqsC3U7k"
        when "aur ho"    then "http://www.youtube.com/watch?v=_vcb29-geqQ"
        when "hawa hawa" then "http://www.youtube.com/watch?v=xQryki2ZhYA"
        when "tum ho"    then "http://www.youtube.com/watch?v=2iUZRSeqzz8"
        when "timer"     then "http://www.youtube.com/watch?v=7xbU0MDQdLM"
        else name
        end
      end

  end
end

World(Ydl::TestHelpers)
