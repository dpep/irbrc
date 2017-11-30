$LOAD_PATH.unshift 'lib'
package_name = 'irbrc'
require "#{package_name}"
package = Object.const_get package_name.capitalize


Gem::Specification.new do |s|
  s.name        = package_name
  s.version     = package.const_get 'VERSION'
  s.authors     = ['Daniel Pepper']
  s.summary     = package.to_s
  s.description = 'irbrc loader'
  s.homepage    = "https://github.com/dpep/rb_#{package_name}"
  s.license     = 'MIT'

  s.files       = Dir.glob('lib/**/*')
  s.test_files  = Dir.glob('test/**/test_*')

  s.add_runtime_dependency 'highline', '~> 1.7'
  s.add_development_dependency 'rake', '~> 10'
  s.add_development_dependency 'minitest', '~> 5'
end