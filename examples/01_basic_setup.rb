#!/usr/bin/env ruby
# frozen_string_literal: true

# 01_basic_setup.rb
# Demonstrates: connecting to the database, creating tables,
# and inspecting the schema programmatically.

require_relative "../lib/my_news"

MyNews.setup(db_path: "db/example_01.db")

db = MyNews.db

puts <<~HEREDOC
  === MyNews Basic Setup ===

  Database tables: #{db.tables.join(", ")}

  Feeds schema:
  #{db.schema(:feeds).map { |col, info| "  %-20s %s" % [col, info[:db_type]] }.join("\n")}

  Entries schema:
  #{db.schema(:entries).map { |col, info| "  %-20s %s" % [col, info[:db_type]] }.join("\n")}

  Feeds in config: #{MyNews.config.feeds.size}
  #{MyNews.config.feeds.map { |f| "  - #{f['name']} (#{f['url']})" }.join("\n")}
HEREDOC
