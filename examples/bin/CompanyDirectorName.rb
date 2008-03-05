require 'examples/ruby/CompanyDirectorName'

include ActiveFacts
include CompanyDirectorName

banner = "="*20
puts "#{banner} Whole vocabulary #{banner}"
puts CompanyDirectorName.verbalise

=begin
print "CompanyName.roles: "
puts CompanyName.roles.verbalise		# =>
print "Name.roles: "
puts Name.roles.verbalise			# =>
print "Date.roles: "
puts CompanyDirectorName::Date.roles.verbalise			# =>
print "Company.roles: "
puts Company.roles.verbalise			# =>
print "Person.roles: "
puts Person.roles.verbalise			# =>
print "Attendance.roles: "
puts Attendance.roles.verbalise			# =>
print "Directorship.roles: "
puts Directorship.roles.verbalise		# =>

print "Company.verbalise: "
Company.verbalise				# =>
print "CompanyName.verbalise: "
CompanyName.verbalise				# =>
puts "Finished concept verbalisation\n\n\n"
=end

puts "#{banner} Creating a constellation #{banner}"
c = ActiveFacts::Constellation.new(CompanyDirectorName)

print "Making a Company:\n\t"
acme = c.Company("Acme, Inc")
puts acme.verbalise

print "Making a Name:\n\t"
given = c.Name("Wile. E.")
puts given.verbalise

print "Making Coyote:\n\t"
coyote = c.Person(given, "Coyote")
puts coyote.verbalise
raise "mismatch!" unless coyote == c.Person("Wile. E.", "Coyote")

print "Assigning Coyote's birth Date:\n\t"
coyote.birth_date = [1949, 9, 16]
puts coyote.birth_date.verbalise

print "Making Roadrunner:\n\t"
roadrunner = c.Person("Road", "Runner")
roadrunner.birth_date = [1949, 9, 16]
puts roadrunner.verbalise

print "Making a Directorship:\n\t"
dir1 = c.Directorship(coyote, acme)
puts dir1.verbalise

print "Assigning director's appointment Date:\n\t"
# Both forms here work:
#dir1.appointment_date = c.Date(1952, 5, 24)
dir1.appointment_date = [1952, 5, 24]
puts dir1.appointment_date.verbalise

print "Making a meeting:\n\t"
meeting = c.Meeting([1952, 05, 24], acme)
puts meeting.verbalise

print "Make that meeting a board meeting:\n\t"
meeting.is_board_meeting = true
puts meeting.verbalise

print "Adding both attendees:\n\t"
puts c.Attendance(meeting, ['Road', 'Runner']).verbalise
puts "\t"+c.Attendance(meeting, coyote).verbalise


#==============================================
puts "#{banner} Whole constellation #{banner}"
puts c.verbalise

#==============================================
puts "#{banner} many-one relationships #{banner}"
print "Coyote's directorships:\n\t"
puts coyote.all_directorship.map{|d| d.verbalise }*"\n\t"
print "Acme's directorships:\n\t"
puts acme.all_directorship.map{|d| d.verbalise }*"\n\t"

print "Acme's meetings:\n\t"
puts acme.all_meeting.map{|d| d.verbalise }*"\n\t"

puts "Date related one-many facts:"
c.Date.each{|date|
  puts "\t"+date.verbalise
  puts(
    ( date.all_meeting.map{|d| d.verbalise }.map{|m| "\t\tMeeting: "+m } +
      date.all_directorship_by_appointment_date.map{|d| d.verbalise }.map{|m| "\t\tAppointment: "+m } +
      date.all_person_by_birth_date.map{|d| d.verbalise }.map{|m| "\t\tBirth: "+m }
    )*"\n"
  )
}

print c.Name[0].verbalise+" person by given name:\n\t"
puts c.Name[0].all_person_by_given_name.map{|d| d.verbalise }*"\n\t"
print c.Name[0].verbalise+" person by family name:\n\t"
puts c.Name[0].all_person_by_family_name.map{|d| d.verbalise }*"\n\t"

print "Person related one-many facts:\n\t"
c.Person.each{|person|
  print person.verbalise+" attendances:\n\t\t"
  puts person.all_attendance.map{|d| d.verbalise }*"\n\t\t"
  print "\t"+person.verbalise+" directorship:\n\t\t"
  puts person.all_directorship.map{|d| d.verbalise }*"\n\t\t"
}

