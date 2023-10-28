require_relative 'lib/irbrc'
package = Irbrc

Gem::Specification.new do |s|
  s.name        = File.basename(__FILE__).split(".")[0]
  s.version     = package.const_get 'VERSION'
  s.authors     = ['Daniel Pepper']
  s.summary     = package.to_s
  s.description = 'irb rc loader'
  s.homepage    = "https://github.com/dpep/irbrc"
  s.license     = 'MIT'
  s.files       = `git ls-files * ':!:spec'`.split("\n")

  s.add_development_dependency "byebug"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
end
