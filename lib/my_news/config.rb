# frozen_string_literal: true

require "myway_config"
require "yaml"

module MyNews
  class Config < MywayConfig::Base
    config_name :my_news
    env_prefix  :my_news
    defaults_path File.expand_path("config/defaults.yml", __dir__)
    auto_configure!

    # Load external YAML lists (feeds, bulletins) and merge into config
    def initialize(config_dir: nil, **kwargs)
      super(**kwargs)
      @config_dir = config_dir || File.expand_path("../../config", __dir__)
      load_external_configs
    end

    def database_path
      database.path
    end

    def fetch_concurrency
      fetch.concurrency
    end

    def user_agent
      fetch.user_agent
    end

    def fetch_timeout
      fetch.timeout
    end

    def llm_provider
      llm.provider
    end

    def llm_model
      llm.model
    end

    def llm_max_tokens
      llm.max_tokens
    end

    def freshrss_url
      freshrss.url
    end

    def freshrss_username
      freshrss.username
    end

    def freshrss_api_key
      freshrss.api_key
    end

    def markdown_dir
      output.markdown_dir
    end

    def html_dir
      output.html_dir
    end

    def schedule_times
      schedule.times
    end

    def schedule_timezone
      schedule.timezone
    end

    private

    def load_external_configs
      feeds_data = load_yaml("feeds.yml")
      external_feeds = feeds_data.fetch("feeds", nil)
      @feeds_list = external_feeds unless external_feeds.nil?

      bulletins_data = load_yaml("bulletins.yml")
      external_themes = bulletins_data.fetch("themes", nil)
      @themes_list = external_themes unless external_themes.nil?
    end

    def load_yaml(filename)
      path = File.join(@config_dir, filename)
      return {} unless File.exist?(path)

      YAML.safe_load_file(path) || {}
    end

    public

    def feeds
      return @feeds_list if @feeds_list

      begin
        Array(super)
      rescue NoMethodError
        []
      end
    end

    def themes
      return @themes_list if @themes_list

      begin
        Array(super)
      rescue NoMethodError
        []
      end
    end
  end
end
