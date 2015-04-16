Gem::Specification.new do |gem|
  gem.name          = "embulk-plugin-input-nicocomment"
  gem.version       = "0.0.1"

  gem.summary       = %q{Embulk Input Plugin niconico douga comment}
  gem.description   = gem.summary
  gem.authors       = ["Tadaichiro Nakano"]
  gem.email         = ["nakanotadaichiro@outlook.jp"]
  gem.homepage      = "https://github.com/tadaichiro/embulk-plugin-input-nicocomment"
  gem.license       = "MIT"

  gem.files         = [ "lib/embulk/input/nicocomment.rb",  "README.md", "LICENSE.txt" ]

  gem.add_development_dependency "bundler", "~> 1.8"
  # spec.add_development_dependency "rake", "~> 10.0"
  # spec.add_development_dependency "rspec"
end
