%w[rubygems rake rake/clean fileutils newgem rubigen spec spec/rake/spectask].each { |f| require f }

require File.dirname(__FILE__) + '/lib/activefacts'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('activefacts', ActiveFacts::VERSION) do |p|
  p.developer('Clifford Heath', 'cjh@dataconstellation.org')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'For more information on ActiveFacts, see http://dataconstellation.com/ActiveFacts'
  p.rubyforge_name       = "cjheath@rubyforge.org"
  p.extra_deps         = [
    ['treetop','>= 1.2.4'],
  ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  p.spec_extras[:extensions] = 'lib/activefacts/cql/Rakefile'
  # Magic Hoe hook to prevent the generation of diagrams:
  ENV['NODOT'] = 'yes'
  p.spec_extras[:rdoc_options] = %w{
      -A has_one -A one_to_one -A maybe
      -x lib/activefacts/cql/.*.rb
      -x lib/activefacts/vocabulary/.*.rb
    }
  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]

Spec::Rake::SpecTask.new(:spec) do |t|
    t.ruby_opts = ['-I', "lib"]
    t.spec_files = FileList['spec/**/*_spec.rb']
    # t.rcov = true
    # t.rcov_opts = ['--exclude', 'spec,/usr/lib/ruby' ]
end
