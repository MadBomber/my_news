# frozen_string_literal: true

module MyNews
  module Fetch
    class Circuit
      def initialize(config: MyNews.config)
        @threshold = config.fetch.circuit_breaker.failure_threshold
        @reset_after = config.fetch.circuit_breaker.reset_after
      end

      def open?(feed)
        failures = feed.consecutive_failures || 0
        return false if failures < @threshold

        last_fetch = feed.last_fetched_at
        return true unless last_fetch

        elapsed = Time.now - last_fetch
        elapsed < @reset_after
      end
    end
  end
end
