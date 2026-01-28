# frozen_string_literal: true

module MyNews
  module Normalize
    class Normalizer
      def initialize(config: MyNews.config, db: MyNews.db, on_result: nil)
        @config = config
        @db = db
        @extractor = Extractor.new(config: config)
        @converter = Converter.new
        @on_result = on_result
      end

      def call
        entries = unprocessed_entries
        count = 0

        entries.each_with_index do |entry, i|
          html = @extractor.extract(entry)
          unless html
            @on_result&.call(entry, :skipped, i + 1, entries.size)
            next
          end

          markdown = @converter.convert(html)
          if markdown.empty?
            @on_result&.call(entry, :skipped, i + 1, entries.size)
            next
          end

          Models::Article.create(
            entry_id:     entry.id,
            markdown:     markdown,
            processed_at: Time.now
          )
          count += 1
          @on_result&.call(entry, :ok, i + 1, entries.size)
        end

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
