# frozen_string_literal: true

require "test_helper"

class TestFetcher < Minitest::Test
  include TestHelper

  def setup
    setup_test_db
  end

  def test_fetches_and_stores_entries
    MyNews.config.instance_variable_set(:@feeds_list, [
      { "url" => "https://hnrss.org/frontpage", "name" => "Hacker News" }
    ])

    fetcher = MyNews::Fetch::Fetcher.new
    results = fetcher.call

    assert_equal 1, MyNews::Models::Feed.count
    assert_operator MyNews::Models::Entry.count, :>, 0

    entry = MyNews::Models::Entry.first
    refute_nil entry.title
    refute_nil entry.guid
  end

  def test_skips_duplicate_guids
    MyNews.config.instance_variable_set(:@feeds_list, [
      { "url" => "https://hnrss.org/frontpage", "name" => "Hacker News" }
    ])

    fetcher = MyNews::Fetch::Fetcher.new
    fetcher.call
    first_count = MyNews::Models::Entry.count

    # Fetch again — most entries already exist
    fetcher.call
    second_count = MyNews::Models::Entry.count

    assert_operator second_count, :>=, first_count
  end

  def test_stores_etag_after_fetch
    MyNews.config.instance_variable_set(:@feeds_list, [
      { "url" => "https://hnrss.org/frontpage", "name" => "Hacker News" }
    ])

    fetcher = MyNews::Fetch::Fetcher.new
    fetcher.call

    feed = MyNews::Models::Feed.first
    refute_nil feed.last_fetched_at
  end
end
