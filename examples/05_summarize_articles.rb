#!/usr/bin/env ruby
# frozen_string_literal: true

# 05_summarize_articles.rb
# Demonstrates: fetching a feed, normalizing to markdown, then
# summarizing articles via LLM. Shows before/after comparison
# of full markdown vs concise summary.

require_relative "../lib/my_news"
require "debug_me"
include DebugMe

DB_PATH = "db/example_05.db"
File.delete(DB_PATH) if File.exist?(DB_PATH)

MyNews.setup(db_path: DB_PATH)
MyNews.config.instance_variable_set(:@feeds_list, [
  { "url" => "https://lobste.rs/rss", "name" => "Lobsters" }
])

# Step 1: Fetch
debug_me "Fetching Lobsters..."
MyNews::Fetch::Fetcher.new.call
debug_me "#{MyNews::Models::Entry.count} entries fetched"

# Step 2: Normalize
debug_me "Normalizing..."
MyNews::Normalize::Normalizer.new.call
debug_me "#{MyNews::Models::Article.count} articles created"

# Step 3: Summarize (limit to 5 for demo speed)
articles = MyNews::Models::Article.where(summary: nil).limit(5).all
summarizer = MyNews::Summarize::Summarizer.new
count = 0

articles.each do |article|
  summary = summarizer.summarize(article.markdown)
  next unless summary

  article.update(summary: summary)
  count += 1
end
debug_me "Summarized #{count} articles"

# Step 4: Display results
summarized = MyNews::Models::Article.exclude(summary: nil).order(:id).limit(5).all

puts <<~HEREDOC

  === Summarization Results ===

  Total articles:      #{MyNews::Models::Article.count}
  Summarized (demo):   #{count}

HEREDOC

summarized.each_with_index do |article, i|
  entry = MyNews::Models::Entry[article.entry_id]
  md_preview = article.markdown.gsub(/\s+/, " ").strip[0, 150]

  puts <<~HEREDOC
    ┌─ #{i + 1}. #{entry.title}
    │
    │  Full text (#{article.markdown.length} chars):
    │  #{md_preview}...
    │
    │  Summary (#{article.summary.length} chars):
    │  #{article.summary}
    │
    └──────────────────────────────────────────

  HEREDOC
end
