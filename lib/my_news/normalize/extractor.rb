# frozen_string_literal: true

require "nokogiri"
require "async"
require "async/barrier"
require "async/semaphore"
require "async/http/internet"

module MyNews
  module Normalize
    class Extractor
      def initialize(config: MyNews.config)
        @config = config
      end

      def extract(entry)
        html = entry.raw_html
        if html.nil? || html.strip.empty?
          html = fetch_full_text(entry.url)
        end
        return nil if html.nil? || html.strip.empty?

        extract_readable(html)
      end

      def fetch_full_text(url)
        return nil unless url

        body = nil
        Async do
          internet = Async::HTTP::Internet.new
          begin
            response = internet.get(url, [["user-agent", @config.user_agent]])
            body = response.read if response.status == 200
          rescue => e
            # Full-text fetch error
          ensure
            internet.close
          end
        end
        body
      end

      private

      def extract_readable(html)
        doc = Nokogiri::HTML(html)

        # Remove scripts, styles, nav, footer, ads
        %w[script style nav footer header aside .ads .sidebar .comments].each do |sel|
          doc.css(sel).remove
        end

        # Prefer <article> or <main> if present
        content = doc.at_css("article") || doc.at_css("main") || doc.at_css("body")
        return nil unless content

        content.to_html
      end
    end
  end
end
