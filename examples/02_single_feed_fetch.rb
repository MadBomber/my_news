#!/usr/bin/env ruby
# frozen_string_literal: true

# 02_single_feed_fetch.rb
# Demonstrates: fetching a single feed, storing entries,
# and querying results via Sequel models.

require_relative "../lib/my_news"
require "debug_me"
include DebugMe

MyNews.setup(db_path: "db/example_02.db")

# Override config to use just one feed
MyNews.config.instance_variable_set(:@feeds, [
  { "url" => "https://lobste.rs/rss", "name" => "Lobsters" }
])

debug_me "Fetching Lobsters feed..."

fetcher = MyNews::Fetch::Fetcher.new
results = fetcher.call

feed = MyNews::Models::Feed.first
entries = MyNews::Models::Entry.where(feed_id: feed.id).all

puts <<~HEREDOC

  === Single Feed Fetch Results ===

  Feed:           #{feed.name}
  URL:            #{feed.url}
  ETag:           #{feed.etag || "(none)"}
  Last-Modified:  #{feed.last_modified || "(none)"}
  Last Fetched:   #{feed.last_fetched_at}
  Entries stored: #{entries.size}

  Latest 5 entries:
  #{entries.first(5).map { |e| "  [#{e.guid[0..30]}] #{e.title}" }.join("\n")}
HEREDOC
