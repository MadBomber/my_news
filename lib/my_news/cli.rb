# frozen_string_literal: true

require "thor"
require "debug_me"

module MyNews
  class CLI < Thor
    include DebugMe

    desc "fetch", "Fetch all enabled RSS feeds"
    def fetch
      MyNews.setup
      fetcher = Fetch::Fetcher.new
      results = fetcher.call

      total_new = 0
      results.each do |feed_id, result|
        feed = Models::Feed[feed_id]
        total_new += result[:new_entries]
        debug_me "#{feed.name}: #{result[:status]} (#{result[:new_entries]} new)"
      end
      debug_me "Total new entries: #{total_new}"
    end

    desc "normalize", "Convert raw entries to markdown articles"
    def normalize
      MyNews.setup
      normalizer = Normalize::Normalizer.new
      normalizer.call
    end

    desc "summarize", "Summarize articles via LLM"
    def summarize
      MyNews.setup
      summarizer = Summarize::Summarizer.new
      summarizer.call
    end

    desc "cluster", "Deduplicate and detect recurring topics"
    def cluster
      MyNews.setup
      Cluster::Deduplicator.new.call
      Cluster::Recurrence.new.call
    end

    desc "publish", "Build and publish themed bulletins"
    def publish
      MyNews.setup
      publisher = Publish::Publisher.new
      publisher.call
    end

    desc "pipeline", "Run full pipeline: fetch → normalize → summarize → cluster → publish"
    def pipeline
      MyNews.setup
      invoke :fetch
      invoke :normalize
      invoke :summarize
      invoke :cluster
      invoke :publish
    end

    desc "schedule", "Run the full pipeline on a cron schedule (3x/day by default)"
    def schedule
      MyNews.setup
      scheduler = Publish::Scheduler.new
      scheduler.start
    end

    desc "search QUERY", "Full-text search articles using FTS5"
    option :limit, type: :numeric, default: 10, desc: "Max results"
    def search(query)
      MyNews.setup
      results = MyNews.db[:articles_fts]
        .where(Sequel.lit("articles_fts MATCH ?", query))
        .limit(options[:limit])
        .select(:rowid, :title, :summary)
        .all

      if results.empty?
        debug_me "No results for '#{query}'"
        return
      end

      puts <<~HEREDOC

        === Search Results for '#{query}' ===

      HEREDOC

      results.each_with_index do |row, i|
        article = Models::Article[row[:rowid]]
        next unless article

        entry = Models::Entry[article.entry_id]
        title = entry&.title || "Untitled"
        summary = article.summary || article.markdown[0, 120]

        puts <<~HEREDOC
          #{i + 1}. #{title}
             #{summary}

        HEREDOC
      end
    end

    desc "feeds", "List all feeds and their status"
    option :all, type: :boolean, default: false, desc: "Include disabled feeds"
    def feeds
      MyNews.setup
      feed_list = options[:all] ? Models::Feed.order(:name).all : Models::Feed.enabled.order(:name).all

      if feed_list.empty?
        debug_me "No feeds configured"
        return
      end

      puts <<~HEREDOC

        === Feeds (#{feed_list.size}) ===

      HEREDOC

      feed_list.each do |feed|
        entry_count = Models::Entry.where(feed_id: feed.id).count
        status = feed.enabled ? "enabled" : "disabled"
        handler = feed.handler ? " [#{feed.handler}]" : ""
        fetched = feed.last_fetched_at ? feed.last_fetched_at.strftime("%Y-%m-%d %H:%M") : "never"

        puts "  %-25s %8s  %4d entries  last: %s%s" % [
          feed.name || feed.url[0, 25], status, entry_count, fetched, handler
        ]
      end
      puts
    end

    desc "feed_add URL", "Add a new feed"
    option :name, type: :string, desc: "Display name for the feed"
    option :handler, type: :string, desc: "Custom handler (hacker_news, mastodon)"
    def feed_add(url)
      MyNews.setup

      if Models::Feed.where(url: url).any?
        debug_me "Feed already exists: #{url}"
        return
      end

      Models::Feed.create(
        url:     url,
        name:    options[:name] || url,
        handler: options[:handler],
        enabled: true
      )
      debug_me "Added feed: #{options[:name] || url}"
    end

    desc "feed_remove URL", "Remove a feed by URL"
    def feed_remove(url)
      MyNews.setup
      feed = Models::Feed.where(url: url).first

      unless feed
        debug_me "Feed not found: #{url}"
        return
      end

      # Remove associated entries and articles
      entry_ids = Models::Entry.where(feed_id: feed.id).select_map(:id)
      Models::Article.where(entry_id: entry_ids).delete unless entry_ids.empty?
      Models::Entry.where(feed_id: feed.id).delete
      feed.delete
      debug_me "Removed feed: #{feed.name || url}"
    end

    desc "feed_toggle URL", "Enable or disable a feed"
    def feed_toggle(url)
      MyNews.setup
      feed = Models::Feed.where(url: url).first

      unless feed
        debug_me "Feed not found: #{url}"
        return
      end

      feed.update(enabled: !feed.enabled)
      state = feed.enabled ? "enabled" : "disabled"
      debug_me "#{feed.name || url}: #{state}"
    end

    desc "status", "Show pipeline status and statistics"
    def status
      MyNews.setup

      feeds_total    = Models::Feed.count
      feeds_enabled  = Models::Feed.enabled.count
      entries_total  = Models::Entry.count
      articles_total = Models::Article.count
      summarized     = Models::Article.exclude(summary: nil).count
      clustered      = Models::Article.exclude(cluster_id: nil).count
      recurring      = Models::Article.where(is_recurring: true).count
      bulletins      = Models::Bulletin.count

      # Recent activity
      cutoff_24h = Time.now - (24 * 3600)
      entries_24h  = Models::Entry.where { fetched_at > cutoff_24h }.count
      articles_24h = Models::Article.where { processed_at > cutoff_24h }.count
      bulletins_24h = Models::Bulletin.where { published_at > cutoff_24h }.count

      # Cluster stats
      cluster_counts = Models::Article.exclude(cluster_id: nil).group_and_count(:cluster_id).all
      dup_groups = cluster_counts.select { |r| r[:count] > 1 }

      puts <<~HEREDOC

        ╔══════════════════════════════════════════════╗
        ║           Pipeline Status                    ║
        ╠══════════════════════════════════════════════╣
        ║                                              ║
        ║  Feeds:          #{feeds_enabled.to_s.rjust(5)} enabled / #{feeds_total.to_s.rjust(5)} total  ║
        ║  Entries:        #{entries_total.to_s.rjust(24)}  ║
        ║  Articles:       #{articles_total.to_s.rjust(24)}  ║
        ║  Summarized:     #{summarized.to_s.rjust(24)}  ║
        ║  Clustered:      #{clustered.to_s.rjust(24)}  ║
        ║  Duplicate groups: #{dup_groups.size.to_s.rjust(22)}  ║
        ║  Recurring:      #{recurring.to_s.rjust(24)}  ║
        ║  Bulletins:      #{bulletins.to_s.rjust(24)}  ║
        ║                                              ║
        ║  --- Last 24 hours ---                       ║
        ║  New entries:    #{entries_24h.to_s.rjust(24)}  ║
        ║  New articles:   #{articles_24h.to_s.rjust(24)}  ║
        ║  Bulletins sent: #{bulletins_24h.to_s.rjust(24)}  ║
        ║                                              ║
        ╚══════════════════════════════════════════════╝

      HEREDOC
    end
  end
end
