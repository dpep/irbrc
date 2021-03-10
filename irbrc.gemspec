$LOAD_PATH.unshift 'lib'
package_name = File.realpath(File.dirname(__FILE__)).split('/').last
require "#{package_name}"
package = Object.const_get package_name.capitalize


Gem::Specification.new do |s|
  s.name        = package_name
  s.version     = package.const_get 'VERSION'
  s.authors     = ['Daniel Pepper']
  s.summary     = package.to_s
  s.description = 'irb rc loader'
  s.homepage    = "https://github.com/dpep/#{package_name}"
  s.license     = 'MIT'

  s.files       = Dir.glob('lib/**/*')
  s.test_files  = Dir.glob('test/**/test_*')

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
end
