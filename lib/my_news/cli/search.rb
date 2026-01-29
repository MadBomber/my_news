# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "search QUERY", "Full-text search articles using FTS5"
    option :limit, type: :numeric, default: 10, desc: "Max results"
    def search(query)
      MyNews.setup
      results = MyNews.db[:articles_fts]
        .where(Sequel.lit("articles_fts MATCH ?", query))
        .limit(options[:limit])
        .select(:rowid, :title, :summary)
        .all

      if results.empty?
        puts "No results for '#{query}'"
        return
      end

      puts <<~HEREDOC

        === Search Results for '#{query}' ===

      HEREDOC

      results.each_with_index do |row, i|
        article = Models::Article[row[:rowid]]
        next unless article

        entry = Models::Entry[article.entry_id]
        title = entry&.title || "Untitled"
        summary = article.summary || article.markdown[0, 120]

        puts <<~HEREDOC
          #{i + 1}. #{title}
             #{summary}

        HEREDOC
      end
    end
  end
end
