#!/usr/bin/env ruby
# frozen_string_literal: true

# 03_full_pipeline_report.rb
# Demonstrates: fetching all configured feeds concurrently,
# ETag caching behavior across runs, per-feed statistics,
# and querying across the full dataset.

require_relative "../lib/my_news"
require "debug_me"
include DebugMe

DB_PATH = "db/example_03.db"

def run_fetch(label)
  debug_me "--- #{label} ---"
  fetcher = MyNews::Fetch::Fetcher.new
  results = fetcher.call

  results.each do |feed_id, result|
    feed = MyNews::Models::Feed[feed_id]
    status = result[:status].to_s.rjust(14)
    debug_me "  #{feed.name.ljust(20)} #{status}  +#{result[:new_entries]} new"
  end

  total = results.values.sum { |r| r[:new_entries] }
  debug_me "  #{"TOTAL".ljust(20)} #{total} new entries"
  puts
  total
end

def print_report
  feeds = MyNews::Models::Feed.all
  total_entries = MyNews::Models::Entry.count

  rows = feeds.map do |f|
    count = MyNews::Models::Entry.where(feed_id: f.id).count
    cached = [f.etag, f.last_modified].compact.any? ? "yes" : "no"
    {
      name:    f.name,
      url:     f.url,
      entries: count,
      cached:  cached,
      enabled: f.enabled ? "yes" : "no"
    }
  end

  header = "%-20s  %7s  %7s  %7s" % %w[Feed Entries Cached Enabled]
  divider = "-" * header.length

  puts <<~HEREDOC
    === Full Pipeline Report ===

    #{header}
    #{divider}
    #{rows.map { |r| "%-20s  %7d  %7s  %7s" % [r[:name], r[:entries], r[:cached], r[:enabled]] }.join("\n")}
    #{divider}
    #{"%-20s  %7d" % ["TOTAL", total_entries]}

    Most recent entries across all feeds:
    #{MyNews::Models::Entry.order(Sequel.desc(:fetched_at)).limit(10).map { |e|
        feed_name = MyNews::Models::Feed[e.feed_id].name
        "  [#{feed_name}] #{e.title}"
      }.join("\n")}

    Database size: #{File.size(DB_PATH)} bytes
  HEREDOC
end

# --- Main ---

MyNews.setup(db_path: DB_PATH)

first_total = run_fetch("First fetch (cold cache)")
second_total = run_fetch("Second fetch (warm cache — expect 304s)")

puts <<~HEREDOC
  Cache effectiveness:
    First run:  #{first_total} new entries
    Second run: #{second_total} new entries
    Savings:    #{first_total - second_total} fewer entries processed

HEREDOC

print_report
