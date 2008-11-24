Examples = %w{
  Address
  Blog
  CompanyDirectorEmployee
  Death
  Genealogy
  Insurance
  Marriage
  Metamodel
  MultiInheritance
  OilSupply
  Orienteering
  OrienteeringER
  PersonPlaysGame
  SchoolActivities
  SimplestUnary
  Warehousing
  WindowInRoomInBldg
}

puts %Q{<table width="100%">
<tr>
<td colspan="5">Table of all examples</td>
</tr>
}

Examples.each {|example|

  image_base = "images/#{example}"
  if File.directory? image_base
    image_files = Dir["#{image_base}/*.png"]
  else
    image_files = [image_base+".png"]
  end
  puts %Q{
<tr>
<td>#{example}</td>
<td><a href="CQL/#{example}.cql">CQL</a></td>
<td><a href="ruby/#{example}.rb">Ruby</a></td>
<td><a href="SQL/#{example}.sql">SQL</a></td>
<td>
#{
  image_files.map { |image|
    %Q{<a href="#{image}">#{File.basename(image, ".png")}</a><br>}
  }*"\n"
}
</tr>
}
}

puts '</table>'
