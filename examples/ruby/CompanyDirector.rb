require "activefacts/api"

module CompanyDirector

  class CompanyName < String
    value_type
    length 48
    single :company, 0..1, "is name of"		# Forward-reference to Company
  end

  class PersonName < String
    value_type
    length 48
    single :person, 0..1, "is name of"		# Forward-reference to Person
  end

  class Company
    entity_type :company_name
    single :company_name, 1..1, "is called"
    multi :directorship				# Where do we squeeze in the mandatory constraint?
    multi :attendance
  end

  class Person
    entity_type :person_name
    single :person_name, 1..1, "is called"
    single :birth_date, 0..1, Date
    multi :directorship
    multi :attendance
  end

  class Attendance
    entity_type :person, :company, :date
    single :person
    single :company
    single :date
    reading ":person attended board meeting of :company on :date"
    reading ":person attended on :date a board meeting for :company"
  end

  class Directorship
    entity_type :person, :company
    single :person    # How to encode the role name Director here?
    single :company
    single :date_appointed, 1..1, Date, "began on"
    reading ":person directs :company"
    reading ":company is directed by :person"
  end

  if __FILE__ == $0

    print "CompanyName.role: "; p CompanyName.role
    print "PersonName.role: "; p PersonName.role
    print "Company.role: "; p Company.role
    print "Person.role: "; p Person.role
    print "Attendance.role: "; p Attendance.role
    print "Directorship.role: "; p Directorship.role

    print "CompanyName.length: "; p CompanyName.length
    print "PersonName.length: "; p PersonName.length

    print "Company.verbalise: "; puts Company.verbalise
    print "CompanyName.verbalise: "; puts CompanyName.verbalise
    print "CompanyName.new('some company').verbalise: "; puts CompanyName.new('some company').verbalise

    (c = Company.new).company_name = "foo"
    c.constellation = 23
    print "Company.new.company_name: "; p c.company_name

    print "Company.new.verbalise: "; puts c.verbalise
    print "CompanyName.verbalise: "; puts CompanyName.verbalise

  end

end
