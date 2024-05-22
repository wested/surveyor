# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "surveyor/version"

Gem::Specification.new do |s|
  s.name = %q{surveyor}
  s.version = Surveyor::VERSION

  s.authors = ["Brian Chamberlain", "Mark Yoon"]
  s.email = %q{yoon@northwestern.edu}
  s.homepage = %q{http://github.com/NUBIC/surveyor}
  s.post_install_message = %q{Thanks for using surveyor! Remember to run the surveyor generator and migrate your database, even if you are upgrading.}
  s.summary = %q{A rails (gem) plugin to enable surveys in your application}

  s.files         = `git ls-files`.split("\n") - ['irb']
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency('rails', '~> 6.1')
  s.add_dependency('haml')
  s.add_dependency('sassc')
  s.add_dependency('formtastic', '>= 4.0.0')
  s.add_dependency('uuidtools', '~> 2.1')
  s.add_dependency('mustache', '~> 1.0')
  s.add_dependency('rabl')
  s.add_dependency('acts_as_list')

  s.add_development_dependency('yard')
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('puma')
  s.add_development_dependency('rspec-rails')
  s.add_development_dependency('rails-controller-testing')
  s.add_development_dependency('capybara')
  s.add_development_dependency('launchy', '~> 2.4.2')
  s.add_development_dependency('selenium-webdriver')
  s.add_development_dependency('cliver', '~> 0.3')
  s.add_development_dependency('json_spec', '~> 1.1.1')
  s.add_development_dependency('factory_bot_rails')
  s.add_development_dependency('database_cleaner')
end

