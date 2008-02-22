require "activefacts/api"

module CompanyDirector
  class Date < ::Date		# Import Date into this Vocabulary
    value_type
    # injected :all_person_by_birth_date
    # injected :all_directorship_by_appointment_date
    # injected :all_attendance
  end

  class Name < String
    value_type :length => 48
    # injected :all_person_by_given_name
    # injected :all_person_by_family_name
  end

  class Person
    entity_type :given_name, :family_name
    role :given_name, Name, :mandatory, "given-:name is name of :person / :person is called given-:name"
    role :family_name, Name, :mandatory, "family-:name is name of :person / :person is called family-:name"
    role :birth_date, Date, ":person was born on birth-:date"

    # injected :all_directorship
    # injected :all_attendance
  end

#  class Employee < Person
#  end

  class CompanyName < String
    value_type :length => 48
    # injected: company
  end

  class Company
    entity_type :company_name
    role :company_name, :mandatory, 1, "is called / is name of"	# Injects CompanyName.company
    # injected: all_directorship
    # injected: all_attendance
  end

  class Directorship
    entity_type :director, :company 		# All identifying role implicitly mandatory
    role :director, Person			# injects Person.all_directorship
    role :company				# injects Company.all_directorship
    role :appointment_date, Date, "began on"	# injects Date.all_directorship_by_appointment_date

    reading ":person directs :company"
    reading ":company is directed by :person"
  end

  class Attendance
    entity_type :person, :company, :date	# All identifying role implicitly mandatory
    role :attendee, Person			# Injects Person.all_attendance
    role :company				# Injects Company.all_attendance
    role :attendance_date, Date			# Injects Date.all_attendance

    reading ":person attended board meeting of :company on :date"
    reading ":person attended on :date a board meeting for :company"
  end

end

if __FILE__ == $0
  include ActiveFacts
  include CompanyDirector

  puts "\n"*4

  if true
    print "CompanyName.roles: "; puts CompanyName.roles.verbalise
    print "Name.roles: "; puts Name.roles.verbalise
    print "Company.roles: "; puts Company.roles.verbalise
    print "Person.roles: "; puts Person.roles.verbalise
    print "Attendance.roles: "; puts Attendance.roles.verbalise
    print "Directorship.roles: "; puts Directorship.roles.verbalise

    print "CompanyName.length: "; p CompanyName.length
    print "Name.length: "; p Name.length

    print "Company.verbalise: "; puts Company.verbalise
    print "CompanyName.verbalise: "; puts CompanyName.verbalise
    puts "Finished concept verbalisation\n\n\n"
  end

  c = ActiveFacts::Constellation.new(CompanyDirector)
  print "Making a Company: "
  acme = c.Company("Acme, Inc")
  puts acme.verbalise
=begin
    - Make/find Name
    - Make/find Company
    - associate Name with Company as .companyName
    - associate Company with Name
=end

  print "Making a Name: "
  given = c.Name("Wile. E.")
  puts given.verbalise
=begin
    - Make/find Name
=end

  print "Making a Person: "
  coyote = c.Person(given, "Coyote")
  puts coyote.verbalise
=begin
    - Make Name Coyote
    - Make Person
    - associate Name "Wile. E" with Person as .givenName
    - associate Name "Coyote" with Person as .familyName
    - associate Person with Name "Wile. E." as .givenNameOf
    - associate Person with Name "Coyote" as .familyNameOf
=end

  print "Making a Directorship: "
  dir1 = c.Directorship(coyote, acme)
  puts dir1.verbalise
=begin
    - Make Directorship object
    - associate person with Directorship
    - associate company with Directorship
    - associate Directorship with person as .directorOf
    - associate Directorship with company as .directorOf
=end

  puts "All Name:\n\t" + c.Name.map{|n| n.verbalise }*"\n\t"
  puts "All Person:\n\t" + c.Person.map{|p| p.verbalise }*"\n\t"
  puts "All CompanyName:\n\t" + c.CompanyName.map{|n| n.verbalise }*"\n\t"
  puts "All Company:\n\t" + c.Company.map{|co| co.verbalise }*"\n\t"
  puts "All Directorship:\n\t" + c.Directorship.map{|d| d.verbalise }*"\n\t"

end
