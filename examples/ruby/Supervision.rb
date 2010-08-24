require 'activefacts/api'

module ::Supervision

  class CompanyName < String
    value_type 
  end

  class EmployeeNr < SignedInteger
    value_type :length => 32
  end

  class Company
    identified_by :company_name
    has_one :ceo, :class => "CEO", :mandatory => true  # See CEO.all_company
    one_to_one :company_name, :mandatory => true  # See CompanyName.company
  end

  class Employee
    identified_by :company, :employee_nr
    has_one :company, :mandatory => true        # See Company.all_employee
    has_one :employee_nr, :mandatory => true    # See EmployeeNr.all_employee
    has_one :manager                            # See Manager.all_employee
  end

  class Manager < Employee
  end

  class CEO < Manager
  end

end
