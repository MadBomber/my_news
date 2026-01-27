# frozen_string_literal: true

require "debug_me"

module MyNews
  module Normalize
    class Normalizer
      include DebugMe

      def initialize(config: MyNews.config, db: MyNews.db)
        @config = config
        @db = db
        @extractor = Extractor.new(config: config)
        @converter = Converter.new
      end

      def call
        entries = unprocessed_entries
        count = 0

        entries.each do |entry|
          html = @extractor.extract(entry)
          next unless html

          markdown = @converter.convert(html)
          next if markdown.empty?

          Models::Article.create(
            entry_id:     entry.id,
            markdown:     markdown,
            processed_at: Time.now
          )
          count += 1
        end

        debug_me "Normalized #{count} entries into articles"
        count
      end

      private

      def unprocessed_entries
        processed_ids = Models::Article.select(:entry_id).map(:entry_id)
        if processed_ids.empty?
          Models::Entry.all
        else
          Models::Entry.exclude(id: processed_ids).all
        end
      end
    end
  end
end
