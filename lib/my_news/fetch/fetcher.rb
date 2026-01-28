# frozen_string_literal: true

require "async"
require "async/barrier"
require "async/semaphore"
require "async/http/internet"
require "rss"
require "console"

module MyNews
  module Fetch
    class Fetcher
      attr_reader :config, :db

      HANDLER_MAP = {
        "hacker_news" => "MyNews::Fetch::Handlers::HackerNews",
        "mastodon"    => "MyNews::Fetch::Handlers::Mastodon"
      }.freeze

      def initialize(config: MyNews.config, db: MyNews.db, on_result: nil)
        @config = config
        @db = db
        @circuit = Circuit.new(config: config)
        @on_result = on_result
      end

      def call
        ensure_feeds_exist
        feeds = Models::Feed.enabled.all
        results = fetch_all(feeds)
        results
      end

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

      private

      def handler_for(feed)
        handler_name = feed.handler
        return Handlers::Base.new(feed) unless handler_name && !handler_name.empty?

        klass_name = HANDLER_MAP[handler_name]
        return Handlers::Base.new(feed) unless klass_name

        Object.const_get(klass_name).new(feed)
      rescue NameError
        Handlers::Base.new(feed)
      end

      def fetch_all(feeds)
        results = {}

        suppress_async_console do
          Async do
            internet = Async::HTTP::Internet.new
            semaphore = Async::Semaphore.new(config.fetch_concurrency)
            barrier = Async::Barrier.new

            feeds.each do |feed|
              if @circuit.open?(feed)
                result = { status: :circuit_open, message: "skipped — #{feed.consecutive_failures} consecutive failures", new_entries: 0 }
                results[feed.id] = result
                notify_result(feed, result)
                next
              end

              barrier.async do
                semaphore.acquire do
                  result = fetch_with_circuit(internet, feed)
                  results[feed.id] = result
                  notify_result(feed, result)
                end
              end
            end

            barrier.wait
          ensure
            barrier&.stop
            internet&.close
          end
        end

        results
      end

      def fetch_with_circuit(internet, feed)
        result = fetch_one(internet, feed)

        if result[:status] == :error
          failures = (feed.consecutive_failures || 0) + 1
          feed.update(consecutive_failures: failures, last_error: result[:message] || "HTTP #{result[:code]}")
        else
          feed.update(consecutive_failures: 0, last_error: nil) if (feed.consecutive_failures || 0) > 0
        end

        result
      end

      def suppress_async_console
        Console.logger.level = :fatal
        yield
      end

      def notify_result(feed, result)
        @on_result&.call(feed, result)
      end

      MAX_REDIRECTS = 5

      def fetch_one(internet, feed)
        handler = handler_for(feed)
        headers = build_headers(feed, handler)
        url = feed.url
        redirects = 0
        timeout = config.fetch_timeout

        Async::Task.current.with_timeout(timeout) do
          loop do
            response = internet.get(url, headers)

            case response.status
            when 304
              return { status: :not_modified, new_entries: 0 }
            when 200
              body = response.read
              body = handler.preprocess_body(body)
              update_cache_headers(feed, response)
              count = parse_and_store(feed, body, handler)
              return { status: :ok, new_entries: count }
            when 301, 302, 303, 307, 308
              redirects += 1
              if redirects > MAX_REDIRECTS
                return { status: :error, message: "too many redirects", new_entries: 0 }
              end
              location = response.headers["location"]
              unless location
                return { status: :error, message: "redirect without location", new_entries: 0 }
              end
              response.read # drain body
              url = location
            else
              return { status: :error, code: response.status, new_entries: 0 }
            end
          end
        end
      rescue Async::TimeoutError
        { status: :error, message: "timeout after #{config.fetch_timeout}s", new_entries: 0 }
      rescue => e
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
