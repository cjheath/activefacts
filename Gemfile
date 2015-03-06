source 'https://rubygems.org'

gem 'activefacts-api', '~> 1', '>= 1.7'
gem 'rbtree-pure', '~> 0', '>= 0.1.1'
gem 'treetop', '~> 1.4', '>= 1.4.14'
gem 'nokogiri', '~> 1', '>= 1.6'

group :development do
  # gem 'debugger', '~> 1', :platforms => [:mri_19, :mri_20]
  # gem 'byebug', '~> 1', :platforms => [:mri_21]
  gem 'activesupport', '~> 4'
  gem 'dm-core', '~> 1', '>= 1.2'
  gem 'dm-constraints', '~> 1', '>= 1.2'
  gem 'dm-migrations', '~> 1', '>= 1.2'
  gem 'jeweler', '~> 2', '>= 2.0'
  gem 'rspec', '~>2.11', '>= 2.11.0'
end

group :test do
  # rcov 1.0.0 is broken for jruby, so 0.9.11 is the only one available.
  gem 'rcov', '~>0.9.11', :platforms => [:jruby, :mri_18], :require => false
  gem 'simplecov', '~>0.6.4', :platforms => :mri_19, :require => false
end
