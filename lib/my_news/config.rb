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
      @config_dir = config_dir || File.expand_path("~/.config/my_news")
      load_external_configs
    end

    def database_path
      File.expand_path(database.path)
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

    def circuit_breaker_threshold
      fetch.circuit_breaker.failure_threshold
    end

    def circuit_breaker_reset_after
      fetch.circuit_breaker.reset_after
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
      list = if @feeds_list
               @feeds_list
             else
               begin
                 Array(super)
               rescue NoMethodError
                 []
               end
             end
      stringify_list(list)
    end

    def themes
      list = if @themes_list
               @themes_list
             else
               begin
                 Array(super)
               rescue NoMethodError
                 []
               end
             end
      stringify_list(list)
    end

    private

    def stringify_list(list)
      list.map { |item| item.is_a?(Hash) ? deep_stringify_keys(item) : item }
    end

    def deep_stringify_keys(hash)
      hash.each_with_object({}) do |(k, v), result|
        result[k.to_s] = v.is_a?(Hash) ? deep_stringify_keys(v) : v
      end
    end
  end
end
