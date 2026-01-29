# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "summarize", "Summarize articles via LLM"
    def summarize
      MyNews.setup
      pending = Models::Article.where(summary: nil).count

      if pending == 0
        puts "No articles to summarize"
        return
      end

      bar = ProgressBar.create(
        title: "Summarizing",
        total: pending,
        format: "%t: |%B| %c/%C %e",
        output: $stdout
      )

      on_progress = ->(_status) {
        bar.increment
      }

      summarizer = Summarize::Summarizer.new(on_progress: on_progress)
      count = summarizer.call
      bar.finish

      skipped = pending - count
      puts "Summarized #{count} articles" + (skipped > 0 ? " (#{skipped} skipped)" : "")
    end
  end
end
