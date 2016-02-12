source 'https://rubygems.org'

gemspec

this_file = File.absolute_path(__FILE__)
if this_file =~ %r{\A#{ENV['HOME']}}i
  dir = File.dirname(File.dirname(this_file))
  $stderr.puts "Using work area gems in #{dir} from activefacts"
  gem 'activefacts-api', path: dir+'/api'
  gem 'activefacts-metamodel', path: dir+'/metamodel'
  gem 'activefacts-cql', path: dir+'/cql'
  gem 'activefacts-orm', path: dir+'/orm'
  gem 'activefacts-rmap', path: dir+'/rmap'
  gem 'activefacts-generators', path: dir+'/generators'
  gem 'activefacts-examples', path: dir+'/examples'
  #gem 'activefacts-compositions', path: dir+'/compositions'
end
