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
    one_to_one :bug_nr, Bug_Nr                  # See Bug_Nr.bug
  end

  class TestCase
    identified_by :test_case_id
    one_to_one :test_case_id, TestCase_Id       # See TestCase_Id.test_case
  end

  class Tester
    identified_by :tester_name
    one_to_one :tester_name, Tester_Name        # See Tester_Name.tester
  end

  class BugReport
    identified_by :tester, :bug
    has_one :bug                                # See Bug.all_bug_report
    has_one :tester                             # See Tester.all_bug_report
    has_one :test_case                          # See TestCase.all_bug_report
  end

end
