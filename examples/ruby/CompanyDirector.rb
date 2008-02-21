require "activefacts/api"

module CompanyDirector

  class Name < String
    value_type :length => 48
    # role :family_name, :person, 0..1, "family-:name is name of / is called family-"
    # role :given_name, :person, 0..1, "given-:name is name of / is called given-"
  end

  class Person
    entity_type :given_name, :family_name
    # role :given_name, Name, 1, "is called given-"
    # role :family_name, Name, 1, "is called family-"
    # role :birth_date, 0..1, Date		# REVISIT: Date doesn't belong to this Vocabulary and isn't a ValueType
    role :directorship
    role :attendance
  end
  fact Person, :given_name, 1..1, "is called given-", Name, :given_name_of, 0..N
  fact Person, :family_name, 1..1, "is called family-", Name, :family_name_of, 0..N
  fact Person, :birth_date, 0..1, "was born on birth-", Date, :birth_date_of, 0..N

  class CompanyName < String
    value_type :length => 48
    role :company, 0..1, "is name of"		# Forward-reference to Company
						# Can this create the Company.company_name role too?
  end

  class Company
    entity_type :company_name
    role :company_name, 1, "is called"		# How is it known that this is the counterpart to CompanyName.company?
    role :directorship, 1..N			# Where do we squeeze in the mandatory constraint?
    role :attendance, 0..N
  end

  class Directorship
    entity_type :person, :company
    role :person, 1    # How to encode the role name Director here?
    role :company, 1
    role :date_appointed, 1, Date, "began on"
    reading ":person directs :company"
    reading ":company is directed by :person"
  end

  class Attendance
    entity_type :person, :company, :date
    role :person, 1
    role :company, 1
    role :date, 1
    reading ":person attended board meeting of :company on :date"
    reading ":person attended on :date a board meeting for :company"
  end

end


if __FILE__ == $0
  include CompanyDirector

  puts "Constructed "+"="*60

=begin
  print "CompanyName.roles: "; p CompanyName.roles
  print "PersonName.roles: "; p PersonName.roles
  print "Company.roles: "; p Company.roles
  print "Person.roles: "; p Person.roles
  print "Attendance.roles: "; p Attendance.roles
  print "Directorship.roles: "; p Directorship.roles

  print "CompanyName.length: "; p CompanyName.length
  print "PersonName.length: "; p PersonName.length

  print "Company.verbalise: "; puts Company.verbalise
  print "CompanyName.verbalise: "; puts CompanyName.verbalise
  print "CompanyName.new('some company').verbalise: "; puts CompanyName.new('some company').verbalise
  c = Company.new("bar")
  c.constellation = 23

  print "Company.new.company_name: "; p c.company_name

  print "Company.new.verbalise: "; puts c.verbalise
  print "CompanyName.verbalise: "; puts CompanyName.verbalise
=end

  c = ActiveFacts::Constellation.new(CompanyDirector)
  co = c.Company("Acme, Inc")
  puts co.verbalise

  p1 = c.Person("Wile E.", "Coyote")
  puts p1.verbalise

  dir1 = c.Directorship(p1, co)
  puts dir1.verbalise

end

