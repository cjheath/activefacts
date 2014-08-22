source 'https://rubygems.org'

gem 'activefacts-api', '~> 1.3'
gem 'rbtree-pure'
gem 'treetop', '>= 1.4.14'
gem 'nokogiri'
gem 'rake'

group :development do
  gem 'debugger', :platforms => [:mri_19, :mri_20]
  gem 'activesupport'
  gem 'dm-core'
  gem 'dm-constraints'
  gem 'dm-migrations'
  gem 'jeweler'
  gem 'rspec', '~>2.11.0'
end

group :test do
  # rcov 1.0.0 is broken for jruby, so 0.9.11 is the only one available.
  gem 'rcov', '~>0.9.11', :platforms => [:jruby, :mri_18], :require => false
  gem 'simplecov', '~>0.6.4', :platforms => :mri_19, :require => false
end
