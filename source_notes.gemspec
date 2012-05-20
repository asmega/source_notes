# -*- encoding: utf-8 -*-
require File.expand_path('../lib/source_notes/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["asmega"]
  gem.email         = ["asmega@ph-lee.com"]
  gem.description   = "Extract source notes aka annotations. Based on Rails SourceAnnotationExtractor."
  gem.summary       = "Extract source notes aka annotations. Based on Rails SourceAnnotationExtractor."
  gem.homepage      = "https://github.com/asmega/source_notes"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "source_notes"
  gem.require_paths = ["lib"]
  gem.version       = SourceNotes::VERSION
end
