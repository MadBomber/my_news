# frozen_string_literal: true

module MyNews
  module Cluster
    class Recurrence
      LOOKBACK_DAYS = 3
      HAMMING_THRESHOLD = 12

      def call
        recent = recent_articles
        older  = older_articles
        return 0 if older.empty?

        count = 0
        recent.each do |article|
          next unless article.simhash
          next if article.is_recurring

          recurring = older.any? do |old|
            old.simhash && Simhash.hamming_distance(article.simhash, old.simhash) <= HAMMING_THRESHOLD
          end

          if recurring
            article.update(is_recurring: true)
            count += 1
          end
        end

        count
      end

      private

      def recent_articles
        cutoff = Time.now - (24 * 3600)
        Models::Article.where { processed_at > cutoff }.exclude(simhash: nil).all
      end

      def older_articles
        cutoff_recent = Time.now - (24 * 3600)
        cutoff_old    = Time.now - (LOOKBACK_DAYS * 24 * 3600)
        Models::Article
          .where { (processed_at <= cutoff_recent) & (processed_at > cutoff_old) }
          .exclude(simhash: nil)
          .all
      end
    end
  end
end
