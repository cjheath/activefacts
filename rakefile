#
# Rakefile for activefacts.
#
# See LICENSE file for copyright notice.
#
require 'rubygems'
Gem::manage_gems
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'
require 'spec'
require 'spec/rake/spectask'

#task :default => [ :test, :rdoc, :packaging, :package ]
task :default => [ :rdoc, :packaging, :package ]

task :spec => :test

rst = Spec::Rake::SpecTask.new(:test) do |t|
    t.ruby_opts = ['-I', "lib"]
    t.spec_files = FileList['spec/**/*_spec.rb']
    # t.rcov = true
    # t.rcov_opts = ['--exclude', 'spec,/usr/lib/ruby' ]
end
#rst.options.files.clear

Rake::RDocTask.new do |rd|
    rd.rdoc_files.include("lib/**/*.rb", "LICENSE")
    rd.rdoc_dir = "docs"
    rd.options << "--accessor=typed_attr"
    rd.options << "--accessor=array_attr"
end

# Create the package task dynamically so FileList happens after RDocTask
CLOBBER.include("pkg")	# Make sure we clean up the gem
task :packaging do
    spec = Gem::Specification.new do |s|
	s.name       = "active_facts"
	s.version    = "0.1.0"
	s.author     = "Clifford Heath"
	s.email      = "clifford dot heath at gmail dot com"
	s.homepage   = "http://rubyforge.org/projects/active_facts"
	s.platform   = Gem::Platform::RUBY
	s.summary    = "Fact-based data modeling and database access"
	s.files      = FileList["{bin,lib,spec}/**/*"].to_a
	s.files      += [ "LICENSE" ]
	s.require_path      = "lib"
	s.autorequire       = "active_facts"
	s.test_file         = "spec/runtest.rb"
	s.has_rdoc          = true
	s.extra_rdoc_files  = []
    end

    Rake::GemPackageTask.new(spec) do |pkg|
	pkg.package_files += FileList["docs/**/*"].exclude(/rdoc$/).to_a
	pkg.need_tar = true
    end
end
