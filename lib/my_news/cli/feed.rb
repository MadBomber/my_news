# frozen_string_literal: true

module MyNews
  class FeedCLI < Thor
    desc "list", "List all feeds and their status"
    option :all, type: :boolean, default: false, desc: "Include disabled feeds"
    def list
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

    desc "add URL", "Add a new feed"
    option :name, type: :string, desc: "Display name for the feed"
    option :handler, type: :string, desc: "Custom handler (hacker_news, mastodon)"
    def add(url)
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

    desc "remove URL", "Remove a feed by URL"
    def remove(url)
      MyNews.setup
      feed = Models::Feed.where(url: url).first

      unless feed
        puts "Feed not found: #{url}"
        return
      end

      name = feed.name || url
      entry_ids = Models::Entry.where(feed_id: feed.id).select_map(:id)
      Models::Article.where(entry_id: entry_ids).delete unless entry_ids.empty?
      Models::Entry.where(feed_id: feed.id).delete
      feed.delete
      puts "Removed feed: #{name}"
    end

    desc "toggle URL", "Enable or disable a feed"
    def toggle(url)
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

    desc "search QUERY", "Search bundled feeds catalog and add selected feeds"
    def search(query)
      MyNews.setup
      catalog = load_feed_catalog
      matches = catalog.select { |f| f["name"].downcase.include?(query.downcase) }

      if matches.empty?
        puts "No feeds matching '#{query}'"
        return
      end

      puts "\n  Feeds matching '#{query}':\n\n"
      matches.each_with_index do |feed, i|
        existing = Models::Feed.where(url: feed["url"]).any?
        status = existing ? " [already added]" : ""
        puts "  %3d. %-30s%s" % [i + 1, feed["name"], status]
      end

      puts "\n  Enter number(s) to add (comma-separated), or 'q' to quit:"
      print "  > "
      input = $stdin.gets&.strip

      return if input.nil? || input.downcase == "q" || input.empty?

      selections = input.split(",").map(&:strip).map(&:to_i)
      added = 0

      selections.each do |num|
        next if num < 1 || num > matches.size

        feed = matches[num - 1]
        if Models::Feed.where(url: feed["url"]).any?
          puts "  Skipped (exists): #{feed["name"]}"
        else
          Models::Feed.create(
            url:     feed["url"],
            name:    feed["name"],
            enabled: true
          )
          puts "  Added: #{feed["name"]}"
          added += 1
        end
      end

      puts "\n  Added #{added} feed(s)" if added > 0
    end

    private

    def load_feed_catalog
      catalog_path = File.expand_path("../../config/feeds.yml", __dir__)
      return [] unless File.exist?(catalog_path)

      data = YAML.safe_load_file(catalog_path) || {}
      data["feeds"] || []
    end

    default_task :list
  end
end
