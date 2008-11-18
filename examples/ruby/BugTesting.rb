require 'activefacts/api'

module BugTesting

  class BugNr < SignedInteger
    value_type :length => 32
  end

  class TestCaseId < AutoCounter
    value_type 
  end

  class TesterName < String
    value_type 
  end

  class Bug
    identified_by :bug_nr
    one_to_one :bug_nr                          # See BugNr.bug
  end

  class TestCase
    identified_by :test_case_id
    one_to_one :test_case_id                    # See TestCaseId.test_case
  end

  class Tester
    identified_by :tester_name
    one_to_one :tester_name                     # See TesterName.tester
  end

  class BugReport
    identified_by :tester, :bug
    has_one :bug                                # See Bug.all_bug_report
    has_one :tester                             # See Tester.all_bug_report
    has_one :test_case                          # See TestCase.all_bug_report
  end

end
