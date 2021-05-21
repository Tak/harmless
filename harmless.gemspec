require_relative 'lib/harmless/version'

Gem::Specification.new do |spec|
  spec.name          = "harmless"
  spec.version       = Harmless::VERSION
  spec.authors       = ["Levi Bard"]
  spec.email         = ["taktaktaktaktaktaktaktaktaktak@gmail.com"]

  spec.summary       = %q{Top-level discord bot functionality aggregator}
  spec.homepage      = "https://github.com/Tak/#{spec.name}"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'discordrb'
  spec.add_dependency 'grue'
  spec.add_dependency 'urika'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
