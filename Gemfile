source 'https://rubygems.org'

gem 'activefacts-api'
gem 'nokogiri'

group :development do
  gem 'jeweler'
  gem 'rspec', '~>2.6.0'
  gem 'rake'
end

group :test do
  # rcov 1.0.0 is broken for jruby, so 0.9.11 is the only one available.
  gem 'rcov', '~>0.9.11', :platforms => [:jruby, :mri_18], :require => false
  gem 'simplecov', '~>0.6.4', :platforms => :mri_19, :require => false
  gem 'rake'
end
