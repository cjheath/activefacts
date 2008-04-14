require 'activefacts/api'

module BugTesting

  class Bug_Nr < SignedInteger
    value_type :length => 32
  end

  class TestCase_Id < AutoCounter
    value_type 
  end

  class Tester_Name < String
    value_type 
  end

  class Bug
    identified_by :bug_nr
    one_to_one :bug_nr, Bug_Nr
  end

  class TestCase
    identified_by :test_case_id
    one_to_one :test_case_id, TestCase_Id
  end

  class Tester
    identified_by :tester_name
    one_to_one :tester_name, Tester_Name
  end

  class BugReport
    identified_by :bug, :tester
    has_one :tester
    has_one :bug
    has_one :test_case
  end

end
