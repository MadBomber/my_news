# frozen_string_literal: true

require_relative "lib/my_news/version"

Gem::Specification.new do |spec|
  spec.name = "my_news"
  spec.version = MyNews::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dewayne@vanhoozer.me"]

  spec.summary = "RSS feed pipeline that transforms feeds into themed bulletins"
  spec.description = "Fetches, normalizes, summarizes, clusters, and publishes RSS feeds as themed bulletins"
  spec.homepage = "https://github.com/madbomber/my_news"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[Gemfile .gitignore test/])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel", "~> 5.0"
  spec.add_dependency "sqlite3", "~> 2.0"
  spec.add_dependency "async", "~> 2.0"
  spec.add_dependency "async-http", "~> 0.75"
  spec.add_dependency "rss", "~> 0.3"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "myway_config"
  spec.add_dependency "nokogiri", "~> 1.16"
  spec.add_dependency "reverse_markdown", "~> 2.1"
  spec.add_dependency "ruby_llm", "~> 1.0"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "rufus-scheduler", "~> 3.9"
end
