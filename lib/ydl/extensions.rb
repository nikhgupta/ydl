require 'digest/md5'

class String
  # Sanitize a given string and strip any illegal characters, and downcase it.
  #
  def simple_sanitize(delimiter = " ")
    fn = self.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
    fn.map! { |s| s.gsub /[^a-z0-9\-\']+/i, delimiter }
    fn.join(".").downcase.strip
  end

  # Quickly create an MD5 hash of the given string
  #
  def md5ify
    (Digest::MD5.new << self).to_s
  end
end

