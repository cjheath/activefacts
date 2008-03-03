require "activefacts/api"

module CompanyDirector
  class Date < ::Date				# Import Date into this Vocabulary
    value_type
  end

  class Name < String
    value_type :length => 48
  end

  class Person
    entity_type :given_name, :family_name
    binary :given_name, Name, :mandatory, "given-:name is name of :person / :person is called given-:name"
    binary :family_name, Name, :mandatory, "family-:name is name of :person / :person is called family-:name"
    binary :birth_date, Date, ":person was born on birth-:date"
  end

  # Will be used for demonstrating subclassing:
  #class Employee < Person
  #end

  class CompanyName < String
    value_type :length => 48
  end

  class Company
    entity_type :company_name
    binary :company_name, :mandatory, 1, "is called / is name of"	# Injects CompanyName.company
  end

  class Directorship
    entity_type :director, :company 		# All identifying role implicitly mandatory
    binary :director, Person			# injects Person.all_directorship
    binary :company				# injects Company.all_directorship
    binary :appointment_date, Date, "began on"	# injects Date.all_directorship_by_appointment_date

    reading ":person directs :company"
    reading ":company is directed by :person"
  end

  class Attendance
    entity_type :person, :company, :attendance_date	# All identifying role implicitly mandatory
    binary :attendee, Person			# Injects Person.all_attendance
    binary :company				# Injects Company.all_attendance
    binary :attendance_date, Date		# Injects Date.all_attendance

    reading ":person attended board meeting of :company on :date"
    reading ":person attended on :date a board meeting for :company"
  end
end

if __FILE__ == $0
  include ActiveFacts
  include CompanyDirector

  if false
    puts "\n"*2

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

  banner = "="*20
  puts "#{banner} Creating a constellation #{banner}"
  c = ActiveFacts::Constellation.new(CompanyDirector)

  print "Making a Company:\n\t"
  acme = c.Company("Acme, Inc")
  puts acme.verbalise

  print "Making a Name:\n\t"
  given = c.Name("Wile. E.")
  puts given.verbalise

  print "Making a Person:\n\t"
  coyote = c.Person(given, "Coyote")
  puts coyote.verbalise
  raise "mismatch!" unless coyote == c.Person("Wile. E.", "Coyote")

  print "Making a Directorship:\n\t"
  dir1 = c.Directorship(coyote, acme)
  puts dir1.verbalise

  print "Assigning director's appointment Date:\n\t"
  # Both forms here work:
  #dir1.appointment_date = c.Date(1952, 4, 28)
  dir1.appointment_date = [1952, 4, 28]
  puts dir1.appointment_date.verbalise

  puts "#{banner} Whole constellation #{banner}"
  puts c.verbalise

  puts "#{banner} many-one relationships #{banner}"
  print "Coyote's directorships:\n\t"
  puts coyote.all_directorship_by_director.map{|d| d.verbalise }*"\n\t"
  print "Acme's directorships:\n\t"
  puts acme.all_directorship.map{|d| d.verbalise }*"\n\t"
  print "Acme's attendances:\n\t"
  puts acme.all_attendance.map{|d| d.verbalise }*"\n\t"
  print c.Date[0].verbalise+" attendances:\n\t"
  puts c.Date[0].all_attendance.map{|d| d.verbalise }*"\n\t"
  print c.Date[0].verbalise+" directorship appointments:\n\t"
  puts c.Date[0].all_directorship_by_appointment_date.map{|d| d.verbalise }*"\n\t"
  print c.Date[0].verbalise+" person birthdates:\n\t"
  puts c.Date[0].all_person_by_birth_date.map{|d| d.verbalise }*"\n\t"
  print c.Name[0].verbalise+" person by given name:\n\t"
  puts c.Name[0].all_person_by_given_name.map{|d| d.verbalise }*"\n\t"
  print c.Name[0].verbalise+" person by family name:\n\t"
  puts c.Name[0].all_person_by_family_name.map{|d| d.verbalise }*"\n\t"
  print c.Name[0].verbalise+" attendances:\n\t"
  puts c.Person[0].all_attendance_by_attendee.map{|d| d.verbalise }*"\n\t"
  print c.Name[0].verbalise+" directorship:\n\t"
  puts c.Person[0].all_directorship_by_director.map{|d| d.verbalise }*"\n\t"

  puts "#{banner} Whole vocabulary #{banner}"
  puts c.vocabulary.verbalise

end
