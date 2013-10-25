# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "redis-cache"
  s.version     = "1.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Anton Ageev"]
  s.email       = ["antage@gmail.com"]
  s.homepage    = "https://github.com/antage/redis-cache"
  s.summary     = %q{ActiveSupport cache adapter for Redis}

  s.files = Dir["README.rdoc", "History.txt", "Rakefile", "lib/**/*.rb"]
  s.test_files = Dir["spec/**/*.rb"]

  s.require_paths = ["lib"]

  s.add_dependency "activesupport", ">= 3.0"
  s.add_dependency "redis", ">= 3.0.0"

  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "i18n", "~> 0.6"
end
