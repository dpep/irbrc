require_relative 'lib/irbrc'

Gem::Specification.new do |s|
  s.name        = 'irbrc'
  s.version     = Irbrc::VERSION
  s.authors     = ['Daniel Pepper']
  s.summary     = 'Irbrc'
  s.description = 'irb rc loader'
  s.homepage    = "https://github.com/dpep/irbrc"
  s.license     = 'MIT'
  s.files       = `git ls-files * ':!:spec'`.split("\n")

  s.add_development_dependency "byebug"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
end
