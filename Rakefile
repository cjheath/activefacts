require 'rubygems'
require 'rake'
require 'fileutils'
require File.dirname(__FILE__) + '/lib/activefacts'

def File.read_utf(path)
  open path, 'rb' do |f|
    f.read.sub %r/\A\xEF\xBB\xBF/, ''
  end
end

def paragraphs_of path, *paragraphs
  File.read_utf(path).delete("\r").split(/\n\n+/).values_at(*paragraphs)
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "activefacts"
  gem.homepage = "http://github.com/cjheath/activefacts"
  gem.license = "MIT"
  gem.version = ActiveFacts::VERSION
  gem.summary = "A semantic modeling and query language (CQL) and application runtime (the Constellation API)"
  gem.description = %q{
ActiveFacts provides a semantic modeling language, the Constellation
Query Language (CQL).  CQL combines natural language verbalisation and
formal logic, producing a formal language that reads like plain
English. ActiveFacts converts semantic models from CQL to relational
and object models in SQL, Ruby and other languages.
}
  # gem.url = "http://dataconstellation.com/ActiveFacts/"

  gem.email = "cjh@dataconstellation.com"
  gem.authors = ["Clifford Heath"]
  gem.add_dependency "activefacts-api", "~>0.9.1"
  gem.add_dependency "treetop"
  gem.add_dependency "nokogiri"
  gem.add_development_dependency "rspec", "~> 2.3.0"
  gem.add_development_dependency "bundler", "~> 1.0.0"
  gem.add_development_dependency "jeweler", "~> 1.5.2"
  # gem.add_development_dependency "rcov", ">= 0"
  gem.add_development_dependency "rdoc", ">= 2.4.2"

  # gem.changes              = paragraphs_of("History.txt", 0..1).join("\n\n")
  gem.extensions = ['lib/activefacts/cql/Rakefile']
  gem.post_install_message = 'For more information on ActiveFacts, see http://dataconstellation.com/ActiveFacts'

  gem.files = File.open("Manifest.txt"){|f| f.read.split(/\n/)}
  gem.executables = gem.files.grep(%r{^bin/}).map{|f| f.sub('bin/', '')}
  gem.rdoc_options = ['-S'] +
    # RDoc used to have these options: -A has_one -A one_to_one -A maybe
    %w{
      -x lib/activefacts/cql/.*.rb
      -x lib/activefacts/vocabulary/.*.rb
    }
end
Jeweler::RubygemsDotOrgTasks.new

# Dir['tasks/**/*.rake'].each { |t| load t }

require 'rspec'
require 'rspec/core/rake_task'

gem "rspec", :require => "spec/rake/spectask"

task :default => :spec

desc "Run Rspec tests"
RSpec::Core::RakeTask.new(:spec) do |t|
    t.ruby_opts = ['-I', "lib"]
    t.rspec_opts = %w{-f d}
    # t.pattern = FileList['spec/**/*_spec.rb']
    # t.rcov = true
    # t.rcov_opts = ['--exclude', 'spec,/usr/lib/ruby' ]
end

desc "Run RSpec tests and produce coverage files (results viewable in coverage/index.html)"
RSpec::Core::RakeTask.new(:coverage) do |spec|
  if RUBY_VERSION < '1.9'
    spec.rcov_opts = [
        '--exclude', 'spec',
        '--exclude', 'gem/*'
      ]
    spec.rcov = true
  else
    spec.rspec_opts = ['--require', 'simplecov_helper']
  end
end

task :cov => :coverage
task :rcov => :coverage
task :simplecov => :coverage
