#
#       ActiveFacts Support code.
#       Version number file.
#
# Copyright (c) 2009 Clifford Heath. Read the LICENSE file.
#
module ActiveFacts
  module Version
    MAJOR = 0
    MINOR = 8
    PATCH = 16

    STRING = [MAJOR, MINOR, PATCH].compact.join('.')
  end
  VERSION = Version::STRING
end
