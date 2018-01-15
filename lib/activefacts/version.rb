#
#       ActiveFacts Support code.
#       Version number file.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Version
    MAJOR = 1
    MINOR = 9
    PATCH = 0

    STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
  VERSION = Version::STRING
end
