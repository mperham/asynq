# frozen_string_literal: true

require_relative "lib/asink/version"

Gem::Specification.new do |spec|
  spec.name = "asink"
  spec.version = Asink::VERSION
  spec.authors = ["Mike Perham"]
  spec.email = ["mike@perham.net"]

  spec.summary = "A lightweight Sidekiq client"
  spec.homepage = "https://sidekiq.org"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://gem.coop"
  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = ""
  # spec.metadata["changelog_uri"] = ""

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .standard.yml])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "redis-client", ">= 0.28"
  spec.add_dependency "json", ">= 2.0.0"
end
