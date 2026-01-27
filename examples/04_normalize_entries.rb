#!/usr/bin/env ruby
# frozen_string_literal: true

# 04_normalize_entries.rb
# Demonstrates: fetching a single feed, normalizing raw HTML entries
# into clean Markdown articles, and inspecting the conversion results.

require_relative "../lib/my_news"
require "debug_me"
include DebugMe

DB_PATH = "db/example_04.db"
File.delete(DB_PATH) if File.exist?(DB_PATH)

MyNews.setup(db_path: DB_PATH)
MyNews.config.instance_variable_set(:@feeds_list, [
  { "url" => "https://feeds.arstechnica.com/arstechnica/index", "name" => "Ars Technica" }
])

# Step 1: Fetch
debug_me "Fetching Ars Technica..."
fetcher = MyNews::Fetch::Fetcher.new
fetcher.call
entry_count = MyNews::Models::Entry.count
debug_me "Fetched #{entry_count} entries"

# Step 2: Normalize
debug_me "Normalizing entries to markdown..."
normalizer = MyNews::Normalize::Normalizer.new
article_count = normalizer.call

# Step 3: Inspect results
articles = MyNews::Models::Article.order(:id).limit(5).all

puts <<~HEREDOC

  === Normalization Results ===

  Raw entries:  #{entry_count}
  Articles:     #{article_count}

  Sample articles:
HEREDOC

articles.each_with_index do |article, i|
  entry = MyNews::Models::Entry[article.entry_id]
  preview = article.markdown.gsub(/\s+/, " ").strip[0, 120]

  puts <<~HEREDOC
    #{i + 1}. #{entry.title}
       Characters: #{article.markdown.length}
       Preview:    #{preview}...

  HEREDOC
end

# Show raw HTML vs Markdown for one entry
first = MyNews::Models::Article.first
entry = MyNews::Models::Entry[first.entry_id]

puts <<~HEREDOC
  === Raw HTML vs Markdown (#{entry.title}) ===

  Raw HTML (first 300 chars):
  #{(entry.raw_html || "")[0, 300]}

  ---

  Markdown (first 500 chars):
  #{first.markdown[0, 500]}
HEREDOC
