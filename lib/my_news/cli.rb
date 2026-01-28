# frozen_string_literal: true

require "thor"
require "fileutils"
require "ruby-progressbar"

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

    desc "init", "Initialize ~/.config/my_news with default configuration"
    def init
      config_dir = File.expand_path("~/.config/my_news")
      db_dir     = File.join(config_dir, "db")
      config_file = File.join(config_dir, "my_news.yml")

      FileUtils.mkdir_p(db_dir)

      if File.exist?(config_file)
        puts "Config already exists: #{config_file}"
      else
        File.write(config_file, <<~YAML)
          # MyNews configuration
          # Overrides bundled defaults. See gem source for all options.
          # Environment variables: MY_NEWS_<SECTION>__<KEY> (e.g. MY_NEWS_LLM__MODEL)

          database:
            path: #{db_dir}/my_news.db

          llm:
            provider: openai
            model: gpt-4o-mini
            # api_key sourced from OPENAI_API_KEY env var

          # schedule:
          #   times:
          #     - "07:00"
          #     - "13:00"
          #     - "19:00"
          #   timezone: America/Chicago
        YAML
        puts "Created: #{config_file}"
      end

      puts <<~HEREDOC

        MyNews initialized at #{config_dir}
          Config: #{config_file}
          Database: #{db_dir}/my_news.db

        Edit #{config_file} to customize settings.
        Run 'my_news fetch' to start.
      HEREDOC
    end

    desc "fetch", "Fetch all enabled RSS feeds"
    def fetch
      MyNews.setup
      total_new = 0
      errors = []
      feed_count = Models::Feed.enabled.count

      bar = ProgressBar.create(
        title: "Fetching",
        total: feed_count,
        format: "%t: |%B| %c/%C %e",
        output: $stdout
      )

      on_result = ->(feed, result) {
        name = feed.name || "Unknown"
        new_count = result[:new_entries]
        total_new += new_count

        case result[:status]
        when :ok
          bar.log "  #{name}: #{new_count} new entries" if new_count > 0
        when :not_modified
          # silent
        when :circuit_open
          bar.log "  #{name}: circuit open (skipped)"
        else
          msg = result[:message] || "HTTP #{result[:code]}"
          errors << "#{name}: #{msg}"
          bar.log "  #{name}: error (#{msg})"
        end
        bar.increment
      }

      fetcher = Fetch::Fetcher.new(on_result: on_result)
      fetcher.call
      bar.finish

      puts "Fetch complete: #{total_new} new entries from #{feed_count} feeds"
      puts "  #{errors.size} feeds had errors" if errors.any?
    end

    desc "normalize", "Convert raw entries to markdown articles"
    def normalize
      MyNews.setup
      processed_ids = Models::Article.select(:entry_id).map(:entry_id)
      pending = if processed_ids.empty?
                  Models::Entry.count
                else
                  Models::Entry.exclude(id: processed_ids).count
                end

      if pending == 0
        puts "No entries to normalize"
        return
      end

      bar = ProgressBar.create(
        title: "Normalizing",
        total: pending,
        format: "%t: |%B| %c/%C %e",
        output: $stdout
      )

      on_result = ->(_entry, _status, _current, _total) {
        bar.increment
      }

      normalizer = Normalize::Normalizer.new(on_result: on_result)
      count = normalizer.call
      bar.finish

      puts "Normalized #{count} entries into articles"
    end

    desc "summarize", "Summarize articles via LLM"
    def summarize
      MyNews.setup
      pending = Models::Article.where(summary: nil).count

      if pending == 0
        puts "No articles to summarize"
        return
      end

      bar = ProgressBar.create(
        title: "Summarizing",
        total: pending,
        format: "%t: |%B| %c/%C %e",
        output: $stdout
      )

      on_progress = ->(_status) {
        bar.increment
      }

      summarizer = Summarize::Summarizer.new(on_progress: on_progress)
      count = summarizer.call
      bar.finish

      skipped = pending - count
      puts "Summarized #{count} articles" + (skipped > 0 ? " (#{skipped} skipped)" : "")
    end

    desc "cluster", "Deduplicate and detect recurring topics"
    def cluster
      MyNews.setup
      puts "Clustering articles..."
      clustered = Cluster::Deduplicator.new.call
      recurring = Cluster::Recurrence.new.call
      puts "Clustered #{clustered || 0} articles into duplicate groups"
      puts "Flagged #{recurring} recurring topics"
    end

    desc "publish", "Build and publish themed bulletins"
    def publish
      MyNews.setup
      puts "Publishing bulletins..."
      publisher = Publish::Publisher.new
      count = publisher.call
      if count > 0
        puts "Published #{count} themed bulletins"
      else
        puts "No bulletins to publish"
      end
    end

    desc "pipeline", "Run full pipeline: fetch → normalize → summarize → cluster → publish"
    def pipeline
      MyNews.setup
      puts "Running full pipeline..."
      invoke :fetch
      invoke :normalize
      invoke :summarize
      invoke :cluster
      invoke :publish
      puts "Pipeline complete"
    end

    map "run" => :pipeline

    desc "schedule", "Run the full pipeline on a cron schedule (3x/day by default)"
    def schedule
      MyNews.setup
      config = MyNews.config
      puts <<~HEREDOC
        Starting scheduler (#{config.schedule_timezone})
        Schedule: #{config.schedule_times.join(", ")}
        Press Ctrl-C to stop.
      HEREDOC
      scheduler = Publish::Scheduler.new
      scheduler.start
      puts "Scheduler stopped."
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
        puts "No results for '#{query}'"
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
        puts "No feeds configured"
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
        puts "Feed already exists: #{url}"
        return
      end

      Models::Feed.create(
        url:     url,
        name:    options[:name] || url,
        handler: options[:handler],
        enabled: true
      )
      puts "Added feed: #{options[:name] || url}"
    end

    desc "feed_remove URL", "Remove a feed by URL"
    def feed_remove(url)
      MyNews.setup
      feed = Models::Feed.where(url: url).first

      unless feed
        puts "Feed not found: #{url}"
        return
      end

      name = feed.name || url
      # Remove associated entries and articles
      entry_ids = Models::Entry.where(feed_id: feed.id).select_map(:id)
      Models::Article.where(entry_id: entry_ids).delete unless entry_ids.empty?
      Models::Entry.where(feed_id: feed.id).delete
      feed.delete
      puts "Removed feed: #{name}"
    end

    desc "feed_toggle URL", "Enable or disable a feed"
    def feed_toggle(url)
      MyNews.setup
      feed = Models::Feed.where(url: url).first

      unless feed
        puts "Feed not found: #{url}"
        return
      end

      feed.update(enabled: !feed.enabled)
      state = feed.enabled ? "enabled" : "disabled"
      puts "#{feed.name || url}: #{state}"
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
