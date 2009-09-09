%w[rubygems hoe rake rake/clean fileutils newgem rubigen spec spec/rake/spectask].each { |f| require f }

require 'hanna/rdoctask'

require File.dirname(__FILE__) + '/lib/activefacts'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec('activefacts') do |p|
  p.version = ActiveFacts::VERSION
  p.summary = "A semantic modeling and query language (CQL) and application runtime (the Constellation API)"
  p.description = %q{
ActiveFacts is a semantic modeling toolkit, comprising an implementation
of the Constellation Query Language, the Constellation API, and code
generators that receive CQL or ORM (Object Role Modeling files, from
NORMA) to emit CQL, Ruby and SQL.

Semantic modeling is a refinement of fact-based modeling techniques
that draw on natural language verbalisation and formal logic. Fact
based modeling is essentially the same as relational modeling in the
sixth normal form. The tools provided here automatically condense
that to third normal form for efficient storage. They also generate
object models as a Ruby module which has an effective mapping to
both the original semantic model and to the generated SQL.

The result is a formal language that reads like plain English, and
allows creation of relational and object models that are guaranteed
equivalent, and much more stable in the face of schema evolution than
SQL is.
}
  p.url = "http://dataconstellation.com/ActiveFacts/"
  p.developer('Clifford Heath', 'cjh@dataconstellation.org')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'For more information on ActiveFacts, see http://dataconstellation.com/ActiveFacts'
  p.rubyforge_name       = "cjheath@rubyforge.org"
  p.extra_deps         = [
    ['treetop','>= 1.4.1'],
  ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  p.spec_extras[:extensions] = 'lib/activefacts/cql/Rakefile'
  # Magic Hoe hook to prevent the generation of diagrams:
  ENV['NODOT'] = 'yes'
  p.spec_extras[:rdoc_options] = %w{
      -S -T hanna
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
