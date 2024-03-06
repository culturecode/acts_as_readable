Gem::Specification.new do |s|
  s.name = 'acts_as_readable'
  s.version = '2.4.0'
  s.email = 'contact@culturecode.ca'
  s.homepage = 'http://github.com/culturecode/acts_as_readable'
  s.summary = "Allows records to be marked as readable. Optimized for bulk, 'mark all as read' operations"
  s.authors = ['Nicholas Jakobsen', 'Ryan Wallace']

  s.require_path = "lib"
  s.files = Dir.glob("{generators,lib,spec}/**/*") + %w(README.rdoc)

  s.add_dependency('rails', ['> 5', '< 8'])
  s.add_development_dependency('pg')
  s.add_development_dependency('rspec-rails', '~> 4')
end
