# frozen_string_literal: true

require "test_helper"

class TestCluster < Minitest::Test
  include TestHelper

  def setup
    setup_test_db
  end

  def test_deduplicator_computes_hashes
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    entry = MyNews::Models::Entry.create(
      feed_id: feed.id, guid: "g1", title: "Ruby 4.0 Released",
      fetched_at: Time.now
    )
    MyNews::Models::Article.create(
      entry_id: entry.id,
      markdown: "Ruby 4.0 has been released with many new features and improvements",
      processed_at: Time.now
    )

    dedup = MyNews::Cluster::Deduplicator.new
    dedup.call

    article = MyNews::Models::Article.first
    refute_nil article.simhash
    refute_nil article.cluster_id
  end

  def test_deduplicator_groups_similar_articles
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")

    shared_text = "Ruby 4.0 has been released today with many new features and significant " \
      "performance improvements for developers around the world. The release includes pattern " \
      "matching enhancements, a new garbage collector, improved YJIT compiler, and better " \
      "support for concurrent programming with fibers and async operations."

    e1 = MyNews::Models::Entry.create(
      feed_id: feed.id, guid: "g1", title: "Ruby 4.0 Released Today",
      fetched_at: Time.now
    )
    e2 = MyNews::Models::Entry.create(
      feed_id: feed.id, guid: "g2", title: "Ruby 4.0 Released Today",
      fetched_at: Time.now
    )

    MyNews::Models::Article.create(
      entry_id: e1.id, markdown: shared_text, processed_at: Time.now
    )
    MyNews::Models::Article.create(
      entry_id: e2.id, markdown: shared_text + " This version marks a major milestone.", processed_at: Time.now
    )

    dedup = MyNews::Cluster::Deduplicator.new
    dedup.call

    articles = MyNews::Models::Article.all
    assert_equal articles[0].cluster_id, articles[1].cluster_id
  end
end
