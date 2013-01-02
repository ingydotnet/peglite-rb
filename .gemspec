# encoding: utf-8

GemSpec = Gem::Specification.new do |gem|
  gem.name = 'peglite'
  gem.version = '0.0.1'
  gem.license = 'MIT'
  gem.required_ruby_version = '>= 1.9.1'

  gem.authors << 'Ingy döt Net'
  gem.email = 'ingy@ingy.net'
  gem.summary = 'Simple PEG Parsing Framework'
  gem.description = <<-'.'
PegLite is a very simple framework for creating your own PEG parsers.
.
  gem.homepage = 'http://pegex.org'

  gem.files = `git ls-files`.lines.map{|l|l.chomp}
end
