# frozen_string_literal: true

require "debug_me"

module MyNews
  module Cluster
    class Deduplicator
      include DebugMe

      HAMMING_THRESHOLD = 10

      def initialize(config: MyNews.config)
        @config = config
      end

      def call
        articles = unhashed_articles
        compute_hashes(articles)
        assign_clusters
      end

      private

      def unhashed_articles
        Models::Article.where(simhash: nil).all
      end

      def compute_hashes(articles)
        articles.each do |article|
          text = [article_title(article), article.markdown].compact.join(" ")
          hash = Simhash.compute(text)
          article.update(simhash: hash)
        end
        debug_me "Computed simhash for #{articles.size} articles"
      end

      def article_title(article)
        entry = Models::Entry[article.entry_id]
        entry&.title
      end

      def assign_clusters
        articles = Models::Article.exclude(simhash: nil).where(cluster_id: nil).all
        next_cluster = (Models::Article.max(:cluster_id) || 0) + 1
        clustered = 0

        articles.each do |article|
          next if article.cluster_id

          # Find all similar unclustered articles
          group = articles.select do |other|
            other.id != article.id &&
              other.cluster_id.nil? &&
              Simhash.hamming_distance(article.simhash, other.simhash) <= HAMMING_THRESHOLD
          end

          article.update(cluster_id: next_cluster)
          group.each { |a| a.update(cluster_id: next_cluster) }

          clustered += group.size + 1 if group.any?
          next_cluster += 1
        end

        debug_me "Assigned #{clustered} articles to clusters"
        clustered
      end
    end
  end
end
