# frozen_string_literal: true

require "test_helper"

class TestDb < Minitest::Test
  include TestHelper

  def setup
    setup_test_db
  end

  def test_creates_feeds_table
    assert MyNews.db.table_exists?(:feeds)
  end

  def test_creates_entries_table
    assert MyNews.db.table_exists?(:entries)
  end

  def test_feed_crud
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    assert_equal "Test", feed.name
    assert_equal true, feed.enabled
  end

  def test_entry_crud
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    entry = MyNews::Models::Entry.create(
      feed_id: feed.id,
      guid: "abc123",
      title: "Hello",
      url: "https://example.com/1",
      fetched_at: Time.now
    )
    assert_equal feed.id, entry.feed_id
    assert_equal "abc123", entry.guid
  end

  def test_entry_guid_unique_per_feed
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    MyNews::Models::Entry.create(feed_id: feed.id, guid: "dup", title: "First", fetched_at: Time.now)
    assert_raises(Sequel::UniqueConstraintViolation) do
      MyNews::Models::Entry.create(feed_id: feed.id, guid: "dup", title: "Second", fetched_at: Time.now)
    end
  end
end
