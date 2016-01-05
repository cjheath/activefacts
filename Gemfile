source 'https://rubygems.org'

gemspec

if ENV['PWD'] =~ %r{\A#{ENV['HOME']}/work}i
  $stderr.puts "Using work area gems for #{File.basename(File.dirname(__FILE__))} from activefacts"
  gem 'activefacts-api', path: '../api'
  gem 'activefacts-metamodel', path: '../metamodel'
  gem 'activefacts-cql', path: '../cql'
  gem 'activefacts-orm', path: '../orm'
  gem 'activefacts-rmap', path: '../rmap'
  gem 'activefacts-generators', path: '../generators'
  gem 'activefacts-examples', path: '../examples'
  #gem 'activefacts-compositions', path: '../compositions'
end
