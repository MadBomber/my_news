# frozen_string_literal: true

require_relative "my_news/version"
require_relative "my_news/config"
require_relative "my_news/db"

module MyNews
  class Error < StandardError; end

  class << self
    attr_accessor :config, :db

    def setup(config_dir: nil, db_path: nil)
      @config = Config.new(config_dir: config_dir)
      @db = DB.connect(db_path || @config.database_path)

      if defined?(Models::Feed)
        Models::Feed.dataset = @db[:feeds]
        Models::Entry.dataset = @db[:entries]
        Models::Article.dataset = @db[:articles]
        Models::Bulletin.dataset = @db[:bulletins]
      else
        require_relative "my_news/models/feed"
        require_relative "my_news/models/entry"
        require_relative "my_news/models/article"
        require_relative "my_news/models/bulletin"
        require_relative "my_news/fetch/handlers/base"
        require_relative "my_news/fetch/handlers/hacker_news"
        require_relative "my_news/fetch/handlers/mastodon"
        require_relative "my_news/fetch/tor_proxy"
        require_relative "my_news/fetch/circuit"
        require_relative "my_news/fetch/fetcher"
        require_relative "my_news/normalize/extractor"
        require_relative "my_news/normalize/converter"
        require_relative "my_news/normalize/normalizer"
        require_relative "my_news/summarize/llm_config"
        require_relative "my_news/summarize/summarizer"
        require_relative "my_news/cluster/simhash"
        require_relative "my_news/cluster/deduplicator"
        require_relative "my_news/cluster/recurrence"
        require_relative "my_news/publish/bulletin_builder"
        require_relative "my_news/publish/file_writer"
        require_relative "my_news/publish/freshrss"
        require_relative "my_news/publish/publisher"
        require_relative "my_news/publish/scheduler"
        require_relative "my_news/cli"
      end
    end
  end
end
