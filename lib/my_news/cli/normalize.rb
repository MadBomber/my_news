# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "normalize", "Convert raw entries to markdown articles"
    def normalize
      MyNews.setup
      processed_ids = Models::Article.select(:entry_id).map(:entry_id)
      pending = if processed_ids.empty?
                  Models::Entry.count
                else
                  Models::Entry.exclude(id: processed_ids).count
                end

      if pending == 0
        puts "No entries to normalize"
        return
      end

      bar = ProgressBar.create(
        title: "Normalizing",
        total: pending,
        format: "%t: |%B| %c/%C %e",
        output: $stdout
      )

      on_result = ->(_entry, _status, _current, _total) {
        bar.increment
      }

      normalizer = Normalize::Normalizer.new(on_result: on_result)
      count = normalizer.call
      bar.finish

      puts "Normalized #{count} entries into articles"
    end
  end
end
