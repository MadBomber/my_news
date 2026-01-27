#!/usr/bin/env ruby
# frozen_string_literal: true

# 07_full_publish.rb
# Demonstrates: the complete pipeline from fetch through publish.
# Fetches live feeds, normalizes, summarizes via LLM, clusters,
# builds themed bulletins, and writes Markdown + HTML output files.
# Shows per-stage statistics and final bulletin contents.

require_relative "../lib/my_news"
require "debug_me"
include DebugMe

DB_PATH  = "db/example_07.db"
OUT_DIR  = "output/example_07"
MD_DIR   = File.join(OUT_DIR, "markdown")
HTML_DIR = File.join(OUT_DIR, "html")

File.delete(DB_PATH) if File.exist?(DB_PATH)
FileUtils.rm_rf(OUT_DIR)

MyNews.setup(db_path: DB_PATH)

# Use two feeds for a manageable demo
MyNews.config.instance_variable_set(:@feeds_list, [
  { "url" => "https://lobste.rs/rss", "name" => "Lobsters" },
  { "url" => "https://feeds.arstechnica.com/arstechnica/index", "name" => "Ars Technica" }
])

stats = {}

# --- Stage 1: Fetch ---
debug_me "Stage 1: Fetch"
fetcher = MyNews::Fetch::Fetcher.new
results = fetcher.call
stats[:entries] = MyNews::Models::Entry.count

results.each do |feed_id, result|
  feed = MyNews::Models::Feed[feed_id]
  debug_me "  #{feed.name}: #{result[:status]} (+#{result[:new_entries]})"
end

# --- Stage 2: Normalize ---
debug_me "Stage 2: Normalize"
normalizer = MyNews::Normalize::Normalizer.new
stats[:articles] = normalizer.call
debug_me "  #{stats[:articles]} articles created"

# --- Stage 3: Summarize (limit to 10 for demo speed) ---
debug_me "Stage 3: Summarize (first 10 articles)"
summarizer = MyNews::Summarize::Summarizer.new
to_summarize = MyNews::Models::Article.where(summary: nil).limit(10).all
stats[:summarized] = 0

to_summarize.each do |article|
  summary = summarizer.summarize(article.markdown)
  next unless summary

  article.update(summary: summary)
  stats[:summarized] += 1
  entry = MyNews::Models::Entry[article.entry_id]
  debug_me "  ✓ #{entry.title[0, 50]}"
end

# --- Stage 4: Cluster ---
debug_me "Stage 4: Cluster"
MyNews::Cluster::Deduplicator.new.call
MyNews::Cluster::Recurrence.new.call

cluster_counts = MyNews::Models::Article.group_and_count(:cluster_id).all
multi_clusters = cluster_counts.select { |r| r[:count] > 1 }
stats[:clusters] = cluster_counts.size
stats[:duplicates] = multi_clusters.sum { |r| r[:count] } rescue 0

# --- Stage 5: Publish ---
debug_me "Stage 5: Publish"

StubConfig = Struct.new(:markdown_dir, :html_dir, :freshrss_url,
                         :freshrss_username, :freshrss_api_key, :themes,
                         keyword_init: true)

pub_config = StubConfig.new(
  markdown_dir:     MD_DIR,
  html_dir:         HTML_DIR,
  freshrss_url:     "",
  freshrss_username: "",
  freshrss_api_key:  "",
  themes:           MyNews.config.themes
)

builder = MyNews::Publish::BulletinBuilder.new(config: pub_config)
bulletins = builder.call

writer = MyNews::Publish::FileWriter.new(config: pub_config)
bulletins.each { |b| writer.write(b) }
stats[:bulletins] = bulletins.size

# --- Report ---
puts <<~HEREDOC

  ╔══════════════════════════════════════════╗
  ║       Full Pipeline Summary              ║
  ╠══════════════════════════════════════════╣
  ║  Entries fetched:    #{stats[:entries].to_s.rjust(18)}  ║
  ║  Articles created:   #{stats[:articles].to_s.rjust(18)}  ║
  ║  Summarized:         #{stats[:summarized].to_s.rjust(18)}  ║
  ║  Clusters:           #{stats[:clusters].to_s.rjust(18)}  ║
  ║  Duplicate groups:   #{multi_clusters.size.to_s.rjust(18)}  ║
  ║  Bulletins:          #{stats[:bulletins].to_s.rjust(18)}  ║
  ╚══════════════════════════════════════════╝

HEREDOC

# Show output files
md_files   = Dir.glob(File.join(MD_DIR, "*.md")).sort
html_files = Dir.glob(File.join(HTML_DIR, "*.html")).sort

puts "  Output files:"
(md_files + html_files).each do |f|
  puts "    #{f} (#{File.size(f)} bytes)"
end
puts

# Show first bulletin preview
if bulletins.any?
  b = bulletins.first
  preview = b.content_md.lines.first(20).join
  puts <<~HEREDOC
    === Preview: #{b.theme} bulletin ===

  #{preview}
    [... #{b.content_md.lines.size - 20} more lines]
  HEREDOC
end
