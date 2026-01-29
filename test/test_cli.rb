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

  def test_feed_cli_responds_to_list
    assert MyNews::FeedCLI.method_defined?(:list)
  end

  def test_feed_cli_responds_to_add
    assert MyNews::FeedCLI.method_defined?(:add)
  end

  def test_feed_cli_responds_to_remove
    assert MyNews::FeedCLI.method_defined?(:remove)
  end

  def test_feed_cli_responds_to_toggle
    assert MyNews::FeedCLI.method_defined?(:toggle)
  end

  def test_feed_cli_responds_to_search
    assert MyNews::FeedCLI.method_defined?(:search)
  end

  def test_cli_responds_to_status
    assert MyNews::CLI.method_defined?(:status)
  end

  def test_cli_responds_to_schedule
    assert MyNews::CLI.method_defined?(:schedule)
  end
end
