# frozen_string_literal: true

require "debug_me"

module MyNews
  module Publish
    class BulletinBuilder
      include DebugMe

      def initialize(config: MyNews.config)
        @config = config
      end

      def call
        themes = @config.themes
        bulletins = []

        themes.each do |theme|
          theme = stringify_keys(theme)
          articles = articles_for_theme(theme)
          next if articles.empty?

          # Non-recurring first, recurring at end
          regular   = articles.reject(&:is_recurring)
          recurring = articles.select(&:is_recurring)
          ordered   = regular + recurring

          content_md = build_markdown(theme["name"], ordered)
          content_html = build_html(theme["name"], ordered)

          bulletin = Models::Bulletin.create(
            theme:        theme["name"],
            content_md:   content_md,
            content_html: content_html,
            published_at: Time.now
          )
          bulletins << bulletin
          debug_me "Built bulletin: #{theme['name']} (#{ordered.size} articles)"
        end

        bulletins
      end

      private

      def stringify_keys(hash)
        hash.transform_keys(&:to_s)
      end

      def articles_for_theme(theme)
        feed_names = theme["feeds"] || []
        keywords   = theme["keywords"] || []

        # Get feed IDs for named feeds
        feed_ids = if feed_names.any?
          Models::Feed.where(name: feed_names).select_map(:id)
        else
          []
        end

        # Get recent articles (last 24h)
        cutoff = Time.now - (24 * 3600)
        candidates = Models::Article.where { processed_at > cutoff }.all

        candidates.select do |article|
          entry = Models::Entry[article.entry_id]
          next false unless entry

          by_feed = feed_ids.include?(entry.feed_id)
          by_keyword = keywords.any? do |kw|
            (entry.title || "").downcase.include?(kw.downcase) ||
              (article.summary || "").downcase.include?(kw.downcase)
          end

          by_feed || by_keyword
        end
      end

      def build_markdown(theme_name, articles)
        lines = ["# #{theme_name.capitalize} Bulletin", ""]
        lines << "_#{Time.now.strftime('%B %d, %Y %H:%M')}_"
        lines << ""

        articles.each_with_index do |article, i|
          entry = Models::Entry[article.entry_id]
          title = entry&.title || "Untitled"
          url   = entry&.url
          summary = article.summary || article.markdown[0, 200]

          lines << "## #{i + 1}. #{title}"
          lines << ""
          lines << summary
          lines << ""
          lines << "[Read more](#{url})" if url
          lines << ""

          if article.is_recurring
            lines << "_Recurring topic_"
            lines << ""
          end
        end

        lines.join("\n")
      end

      def build_html(theme_name, articles)
        parts = []
        parts << "<html><head><title>#{theme_name.capitalize} Bulletin</title></head><body>"
        parts << "<h1>#{theme_name.capitalize} Bulletin</h1>"
        parts << "<p><em>#{Time.now.strftime('%B %d, %Y %H:%M')}</em></p>"

        articles.each_with_index do |article, i|
          entry = Models::Entry[article.entry_id]
          title = entry&.title || "Untitled"
          url   = entry&.url
          summary = article.summary || article.markdown[0, 200]

          parts << "<h2>#{i + 1}. #{title}</h2>"
          parts << "<p>#{summary}</p>"
          parts << "<p><a href=\"#{url}\">Read more</a></p>" if url
          parts << "<p><em>Recurring topic</em></p>" if article.is_recurring
        end

        parts << "</body></html>"
        parts.join("\n")
      end
    end
  end
end
