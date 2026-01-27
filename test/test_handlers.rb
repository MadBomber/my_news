# frozen_string_literal: true

require "test_helper"
require "rss"

class TestHandlers < Minitest::Test
  include TestHelper

  def setup
    setup_test_db
  end

  def test_base_handler_transforms_rss_item
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    handler = MyNews::Fetch::Handlers::Base.new(feed)

    item = build_rss_item(
      title: "Test Article",
      link: "https://example.com/1",
      guid: "guid-1",
      description: "<p>Hello world</p>"
    )

    data = handler.transform(item)

    assert_equal "guid-1", data[:guid]
    assert_equal "Test Article", data[:title]
    assert_equal "https://example.com/1", data[:url]
    assert_includes data[:raw_html], "Hello world"
  end

  def test_base_handler_returns_nil_for_nil_item_gracefully
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    handler = MyNews::Fetch::Handlers::Base.new(feed)

    # Base handler returns a hash even with minimal data
    item = build_rss_item(title: "Minimal", link: nil, guid: nil, description: nil)
    data = handler.transform(item)
    assert_kind_of Hash, data
  end

  def test_hacker_news_handler_appends_comments_link
    feed = MyNews::Models::Feed.create(url: "https://hnrss.org/frontpage", name: "HN", handler: "hacker_news")
    handler = MyNews::Fetch::Handlers::HackerNews.new(feed)

    item = build_rss_item(
      title: "Show HN: Something Cool",
      link: "https://example.com/cool",
      guid: "https://news.ycombinator.com/item?id=12345",
      description: "<p>Cool project</p>"
    )

    data = handler.transform(item)
    assert_includes data[:raw_html], "HN Discussion"
  end

  def test_mastodon_handler_fills_empty_title
    feed = MyNews::Models::Feed.create(url: "https://mastodon.social/@user.rss", name: "Mastodon", handler: "mastodon")
    handler = MyNews::Fetch::Handlers::Mastodon.new(feed)

    item = build_rss_item(
      title: "",
      link: "https://mastodon.social/@user/123",
      guid: "masto-123",
      description: "<p>This is a toot about Ruby programming and open source software development.</p>"
    )

    data = handler.transform(item)
    refute_empty data[:title]
    assert_includes data[:title], "toot about Ruby"
  end

  def test_fetcher_handler_map_resolves_known_handlers
    feed_hn = MyNews::Models::Feed.create(url: "https://hnrss.org/frontpage", name: "HN", handler: "hacker_news")
    feed_masto = MyNews::Models::Feed.create(url: "https://mastodon.social/@user.rss", name: "Masto", handler: "mastodon")
    feed_plain = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Plain")

    fetcher = MyNews::Fetch::Fetcher.new

    hn_handler = fetcher.send(:handler_for, feed_hn)
    assert_instance_of MyNews::Fetch::Handlers::HackerNews, hn_handler

    masto_handler = fetcher.send(:handler_for, feed_masto)
    assert_instance_of MyNews::Fetch::Handlers::Mastodon, masto_handler

    plain_handler = fetcher.send(:handler_for, feed_plain)
    assert_instance_of MyNews::Fetch::Handlers::Base, plain_handler
  end

  def test_tor_proxy_not_available_by_default
    refute MyNews::Fetch::TorProxy.available?
  end

  private

  def build_rss_item(title:, link:, guid:, description:)
    require "cgi"
    escaped_desc = description ? CGI.escapeHTML(description) : nil

    rss_source = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test</title>
          <item>
            #{"<title>#{title}</title>" if title}
            #{"<link>#{link}</link>" if link}
            #{"<guid>#{guid}</guid>" if guid}
            #{"<description>#{escaped_desc}</description>" if escaped_desc}
          </item>
        </channel>
      </rss>
    XML

    parsed = RSS::Parser.parse(rss_source, false)
    parsed.items.first
  end
end
