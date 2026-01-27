# frozen_string_literal: true

require "async"
require "async/barrier"
require "async/semaphore"
require "async/http/internet"
require "rss"
require "debug_me"

module MyNews
  module Fetch
    class Fetcher
      include DebugMe

      attr_reader :config, :db

      HANDLER_MAP = {
        "hacker_news" => "MyNews::Fetch::Handlers::HackerNews",
        "mastodon"    => "MyNews::Fetch::Handlers::Mastodon"
      }.freeze

      def initialize(config: MyNews.config, db: MyNews.db)
        @config = config
        @db = db
      end

      def call
        ensure_feeds_exist
        feeds = Models::Feed.enabled.all
        results = fetch_all(feeds)
        results
      end

      private

      def ensure_feeds_exist
        config.feeds.each do |feed_data|
          next if Models::Feed.where(url: feed_data["url"]).any?

          Models::Feed.create(
            url:     feed_data["url"],
            name:    feed_data["name"],
            handler: feed_data["handler"],
            enabled: feed_data.fetch("enabled", true)
          )
        end
      end

      def handler_for(feed)
        handler_name = feed.handler
        return Handlers::Base.new(feed) unless handler_name && !handler_name.empty?

        klass_name = HANDLER_MAP[handler_name]
        return Handlers::Base.new(feed) unless klass_name

        Object.const_get(klass_name).new(feed)
      rescue NameError
        debug_me "Unknown handler '#{handler_name}', using base"
        Handlers::Base.new(feed)
      end

      def fetch_all(feeds)
        results = {}

        Async do
          internet = Async::HTTP::Internet.new
          semaphore = Async::Semaphore.new(config.fetch_concurrency)
          barrier = Async::Barrier.new

          feeds.each do |feed|
            barrier.async do
              semaphore.acquire do
                results[feed.id] = fetch_one(internet, feed)
              end
            end
          end

          barrier.wait
        ensure
          internet&.close
        end

        results
      end

      def fetch_one(internet, feed)
        handler = handler_for(feed)
        headers = build_headers(feed, handler)
        response = internet.get(feed.url, headers)

        case response.status
        when 304
          { status: :not_modified, new_entries: 0 }
        when 200
          body = response.read
          body = handler.preprocess_body(body)
          update_cache_headers(feed, response)
          count = parse_and_store(feed, body, handler)
          { status: :ok, new_entries: count }
        else
          { status: :error, code: response.status, new_entries: 0 }
        end
      rescue => e
        debug_me "Fetch error for #{feed.url}: #{e.message}"
        { status: :error, message: e.message, new_entries: 0 }
      end

      def build_headers(feed, handler)
        h = [["user-agent", config.user_agent]]
        h << ["if-none-match", feed.etag] if feed.etag
        h << ["if-modified-since", feed.last_modified] if feed.last_modified
        h += handler.extra_headers
        h
      end

      def update_cache_headers(feed, response)
        etag = response.headers["etag"]
        last_mod = response.headers["last-modified"]
        feed.update(
          etag: etag,
          last_modified: last_mod,
          last_fetched_at: Time.now
        )
      end

      def parse_and_store(feed, body, handler)
        parsed = RSS::Parser.parse(body, false)
        return 0 unless parsed

        count = 0
        parsed.items.each do |item|
          data = handler.transform(item)
          next unless data

          guid = data[:guid]
          next if Models::Entry.where(feed_id: feed.id, guid: guid).any?

          Models::Entry.create(
            feed_id:    feed.id,
            guid:       guid,
            title:      data[:title],
            url:        data[:url],
            raw_html:   data[:raw_html],
            fetched_at: Time.now
          )
          count += 1
        end
        count
      end
    end
  end
end
