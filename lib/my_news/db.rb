# frozen_string_literal: true

require "sequel"
require "fileutils"

module MyNews
  module DB
    module_function

    def connect(path = nil)
      path ||= MyNews.config.database_path
      FileUtils.mkdir_p(File.dirname(path))
      db = Sequel.sqlite(path)
      create_tables(db)
      db
    end

    def create_tables(db)
      db.create_table?(:feeds) do
        primary_key :id
        String :url, null: false, unique: true
        String :name
        String :handler
        String :etag
        String :last_modified
        Time :last_fetched_at
        TrueClass :enabled, default: true
        Integer :consecutive_failures, default: 0
        String :last_error
      end

      db.create_table?(:entries) do
        primary_key :id
        foreign_key :feed_id, :feeds
        String :guid, null: false
        String :title
        String :url
        Text :raw_html
        Time :fetched_at, null: false
        unique [:feed_id, :guid]
      end

      db.create_table?(:articles) do
        primary_key :id
        foreign_key :entry_id, :entries, unique: true
        Text :markdown, null: false
        Text :summary
        Bignum :simhash
        Integer :cluster_id
        TrueClass :is_recurring, default: false
        Time :processed_at, null: false
      end

      db.create_table?(:bulletins) do
        primary_key :id
        String :theme, null: false
        Text :content_md
        Text :content_html
        Time :published_at
        TrueClass :pushed_freshrss, default: false
      end

      migrate_feeds(db)
      create_fts(db)
    end

    def migrate_feeds(db)
      columns = db[:feeds].columns
      unless columns.include?(:consecutive_failures)
        db.alter_table(:feeds) do
          add_column :consecutive_failures, Integer, default: 0
          add_column :last_error, String
        end
      end
    end

    def create_fts(db)
      db.run <<~SQL unless db.tables.include?(:articles_fts)
        CREATE VIRTUAL TABLE articles_fts USING fts5(
          title, markdown, summary,
          content='articles',
          content_rowid='id',
          tokenize='porter'
        );
      SQL
    end
  end
end
