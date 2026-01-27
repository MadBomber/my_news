# frozen_string_literal: true

require "test_helper"

class TestCli < Minitest::Test
  def test_cli_responds_to_fetch
    assert MyNews::CLI.method_defined?(:fetch)
  end

  def test_cli_is_a_thor
    assert MyNews::CLI < Thor
  end

  def test_cli_responds_to_search
    assert MyNews::CLI.method_defined?(:search)
  end

  def test_cli_responds_to_feeds
    assert MyNews::CLI.method_defined?(:feeds)
  end

  def test_cli_responds_to_feed_add
    assert MyNews::CLI.method_defined?(:feed_add)
  end

  def test_cli_responds_to_feed_remove
    assert MyNews::CLI.method_defined?(:feed_remove)
  end

  def test_cli_responds_to_feed_toggle
    assert MyNews::CLI.method_defined?(:feed_toggle)
  end

  def test_cli_responds_to_status
    assert MyNews::CLI.method_defined?(:status)
  end

  def test_cli_responds_to_schedule
    assert MyNews::CLI.method_defined?(:schedule)
  end
end
