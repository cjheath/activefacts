source 'https://rubygems.org'

gemspec

if ENV['PWD'] =~ %r{\A#{ENV['HOME']}/work}
  puts "Using work area gems for #{File.basename(File.dirname(__FILE__))}"
  gem 'activefacts-api', path: '/Users/cjh/work/activefacts/api'
  gem 'activefacts-metamodel', path: '/Users/cjh/work/activefacts/metamodel'
  gem 'activefacts-cql', path: '/Users/cjh/work/activefacts/cql'
  gem 'activefacts-orm', path: '/Users/cjh/work/activefacts/orm'
  gem 'activefacts-rmap', path: '/Users/cjh/work/activefacts/rmap'
  #gem 'activefacts-compositions', path: '/Users/cjh/work/activefacts/compositions'
  gem 'activefacts-generators', path: '/Users/cjh/work/activefacts/generators'
  gem 'activefacts-examples', path: '/Users/cjh/work/activefacts/examples'
end
