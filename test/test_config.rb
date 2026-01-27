# frozen_string_literal: true

require "test_helper"

class TestConfig < Minitest::Test
  def test_database_path
    config = MyNews::Config.new
    refute_nil config.database_path
    assert_kind_of String, config.database_path
  end

  def test_fetch_concurrency
    config = MyNews::Config.new
    assert_kind_of Integer, config.fetch_concurrency
    assert_operator config.fetch_concurrency, :>, 0
  end

  def test_user_agent
    config = MyNews::Config.new
    assert_match(/MyNews/, config.user_agent)
  end

  def test_fetch_timeout
    config = MyNews::Config.new
    assert_kind_of Integer, config.fetch_timeout
  end

  def test_llm_model
    config = MyNews::Config.new
    refute_nil config.llm_model
  end

  def test_loads_feeds_from_external_yaml
    config = MyNews::Config.new
    assert_kind_of Array, config.feeds
    refute_empty config.feeds
  end

  def test_loads_themes_from_external_yaml
    config = MyNews::Config.new
    assert_kind_of Array, config.themes
    refute_empty config.themes
  end

  def test_schedule_times
    config = MyNews::Config.new
    assert_kind_of Array, config.schedule_times
  end

  def test_nested_config_access
    config = MyNews::Config.new
    assert_respond_to config, :database
    assert_respond_to config, :fetch
    assert_respond_to config, :llm
  end

  def test_missing_config_dir_still_returns_feeds
    config = MyNews::Config.new(config_dir: "/nonexistent")
    assert_equal [], config.feeds
    assert_equal [], config.themes
  end

  def test_env_override
    ENV["MY_NEWS_FETCH__CONCURRENCY"] = "42"
    config = MyNews::Config.new
    assert_equal 42, config.fetch_concurrency.to_i
  ensure
    ENV.delete("MY_NEWS_FETCH__CONCURRENCY")
  end
end
