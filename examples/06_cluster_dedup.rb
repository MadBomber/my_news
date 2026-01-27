#!/usr/bin/env ruby
# frozen_string_literal: true

# 06_cluster_dedup.rb
# Demonstrates: SimHash fingerprinting, hamming distance calculation,
# duplicate detection, and cluster assignment. Seeds synthetic
# duplicate content to show clustering in action.

require_relative "../lib/my_news"
require "debug_me"
include DebugMe

DB_PATH = "db/example_06.db"
File.delete(DB_PATH) if File.exist?(DB_PATH)

MyNews.setup(db_path: DB_PATH)

# Seed synthetic data with known duplicates
debug_me "Seeding synthetic articles with duplicates..."

feed = MyNews::Models::Feed.create(url: "https://example.com/feed1", name: "Feed A")
feed2 = MyNews::Models::Feed.create(url: "https://example.com/feed2", name: "Feed B")

articles_data = [
  { feed: feed,  guid: "a1", title: "Ruby 4.0 Released With Major Performance Gains",
    text: "Ruby 4.0 has been officially released bringing massive performance improvements " \
          "through an enhanced YJIT compiler, new pattern matching syntax, and improved " \
          "garbage collection. The release represents years of work by the Ruby core team " \
          "to make the language competitive with compiled alternatives." },

  { feed: feed2, guid: "b1", title: "Ruby 4.0 Launches With Significant Speed Boosts",
    text: "Ruby 4.0 has been officially released bringing massive performance improvements " \
          "through an enhanced YJIT compiler, new pattern matching syntax, and improved " \
          "garbage collection. The update represents years of effort by the Ruby core team " \
          "to make the language competitive with compiled alternatives." },

  { feed: feed,  guid: "a2", title: "SpaceX Launches Starship on Seventh Test Flight",
    text: "SpaceX successfully launched its Starship rocket on its seventh test flight from " \
          "Boca Chica Texas reaching orbital velocity before a controlled ocean landing. " \
          "The flight demonstrated significant progress toward full reusability with the " \
          "super heavy booster returning to the launch tower for the third time." },

  { feed: feed2, guid: "b2", title: "Starship Reaches Orbit on Latest SpaceX Test",
    text: "SpaceX successfully launched its Starship rocket on its seventh test flight from " \
          "Boca Chica Texas reaching orbital velocity before a controlled ocean splashdown. " \
          "The mission showed major advances toward full reusability with the super heavy " \
          "booster caught by the launch tower for the third consecutive time." },

  { feed: feed,  guid: "a3", title: "PostgreSQL 18 Adds Native JSON Path Queries",
    text: "PostgreSQL 18 introduces native JSON path query support, bringing powerful " \
          "document database capabilities to the relational engine. The feature allows " \
          "developers to query nested JSON structures using SQL standard path expressions " \
          "without external extensions or cumbersome workarounds." },

  { feed: feed,  guid: "a4", title: "New CSS Container Queries Ship in All Browsers",
    text: "Container queries have finally shipped in all major browsers enabling truly " \
          "component-responsive design without relying on viewport-based media queries. " \
          "Frontend developers can now build self-contained UI components that adapt their " \
          "layout based on the size of their parent container rather than the window." },
]

articles_data.each do |data|
  entry = MyNews::Models::Entry.create(
    feed_id: data[:feed].id, guid: data[:guid], title: data[:title],
    url: "https://example.com/#{data[:guid]}", fetched_at: Time.now
  )
  MyNews::Models::Article.create(
    entry_id: entry.id, markdown: data[:text], processed_at: Time.now
  )
end

debug_me "Seeded #{MyNews::Models::Article.count} articles"

# Show SimHash for each article
puts <<~HEREDOC

  === SimHash Fingerprints ===
HEREDOC

MyNews::Models::Article.order(:id).each do |article|
  entry = MyNews::Models::Entry[article.entry_id]
  text = [entry.title, article.markdown].join(" ")
  hash = MyNews::Cluster::Simhash.compute(text)
  puts "  %016X  %s" % [hash, entry.title]
end

# Show pairwise hamming distances
puts <<~HEREDOC

  === Pairwise Hamming Distances ===
HEREDOC

articles = MyNews::Models::Article.order(:id).all
articles.combination(2) do |a, b|
  next unless a.simhash.nil? # compute first

  text_a = [MyNews::Models::Entry[a.entry_id].title, a.markdown].join(" ")
  text_b = [MyNews::Models::Entry[b.entry_id].title, b.markdown].join(" ")
  a.update(simhash: MyNews::Cluster::Simhash.compute(text_a))
  b.update(simhash: MyNews::Cluster::Simhash.compute(text_b))
end

# Refresh and compute all distances
articles = MyNews::Models::Article.order(:id).all
articles.combination(2) do |a, b|
  dist = MyNews::Cluster::Simhash.hamming_distance(a.simhash, b.simhash)
  t1 = MyNews::Models::Entry[a.entry_id].title[0, 35]
  t2 = MyNews::Models::Entry[b.entry_id].title[0, 35]
  marker = dist <= 10 ? " ← DUPLICATE" : ""
  puts "  distance=%2d  %-35s  ↔  %-35s%s" % [dist, t1, t2, marker]
end

# Run the deduplicator
puts ""
debug_me "Running deduplicator..."
MyNews::Cluster::Deduplicator.new.call

# Show cluster results
puts <<~HEREDOC

  === Cluster Assignments ===
HEREDOC

MyNews::Models::Article.order(:cluster_id, :id).each do |article|
  entry = MyNews::Models::Entry[article.entry_id]
  puts "  Cluster %2d  %s" % [article.cluster_id, entry.title]
end

# Summary
cluster_counts = MyNews::Models::Article.group_and_count(:cluster_id).all
multi = cluster_counts.select { |r| r[:count] > 1 }

puts <<~HEREDOC

  === Summary ===
  Total articles:     #{articles.size}
  Total clusters:     #{cluster_counts.size}
  Duplicate groups:   #{multi.size}
  Unique articles:    #{cluster_counts.size - multi.size + multi.sum { |r| 1 }}
HEREDOC
