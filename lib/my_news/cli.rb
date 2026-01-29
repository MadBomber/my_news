# frozen_string_literal: true

require "thor"
require "fileutils"
require "ruby-progressbar"
require "yaml"

module MyNews
  class CLI < Thor
    package_name "MyNews"

    def self.banner_header
      <<~HEADER

        my_news v#{MyNews::VERSION} — RSS feed pipeline that transforms feeds into themed bulletins

      HEADER
    end

    def self.help(shell, subcommand = false)
      shell.say banner_header
      super
      shell.say "\n"
    end
  end
end

# Load subcommands first (must be defined before registration)
require_relative "cli/feed"

# Load command definitions (reopen CLI class)
require_relative "cli/init"
require_relative "cli/fetch"
require_relative "cli/normalize"
require_relative "cli/summarize"
require_relative "cli/cluster"
require_relative "cli/publish"
require_relative "cli/pipeline"
require_relative "cli/schedule"
require_relative "cli/search"
require_relative "cli/status"

# Register subcommands after all classes are loaded
module MyNews
  class CLI < Thor
    desc "feed SUBCOMMAND", "Manage feeds (add, remove, toggle, list, search)"
    subcommand "feed", FeedCLI
  end
end
