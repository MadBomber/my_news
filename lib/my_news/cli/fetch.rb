# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "fetch", "Fetch all enabled RSS feeds"
    def fetch
      MyNews.setup
      total_new = 0
      errors = []
      Fetch::Fetcher.new.ensure_feeds_exist
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
  end
end
