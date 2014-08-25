Gem.post_install do |installer|
  if installer.spec.name == 'activefacts'
    pattern = installer.dir + '/lib/activefacts/cql/**/*.treetop'
    files = Dir[pattern]
    # Hopefully this quoting will work where there are spaces in filenames, and even maybe on Windows?
    cmd = "tt '#{files*"' '"}'"
    puts "Compiling Treetop grammars:"
    puts cmd
    system cmd
    puts 'For more information on ActiveFacts, see http://dataconstellation.com/ActiveFacts/'
  end
end
