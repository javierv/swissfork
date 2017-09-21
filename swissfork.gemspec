$:.push File.expand_path("../lib", __FILE__)
require "swissfork/version"

Gem::Specification.new do |s|
  s.name        = "swissfork"
  s.version     = Swissfork::VERSION
  s.authors     = ["Javier Martín"]
  s.email       = ["javier@elretirao.net"]
  s.homepage    = ""
  s.summary     = %q{Chess Swiss System pairing program}
  s.description = %q{Manages chess tournaments using the Swiss System pairing}

  s.rubyforge_project = "swissfork"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 3.6.0"
end
