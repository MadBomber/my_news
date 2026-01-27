# frozen_string_literal: true

require "test_helper"

class TestNormalizer < Minitest::Test
  include TestHelper

  def setup
    setup_test_db
  end

  def test_converter_html_to_markdown
    converter = MyNews::Normalize::Converter.new
    html = "<h1>Title</h1><p>Hello <strong>world</strong></p>"
    md = converter.convert(html)
    assert_includes md, "Title"
    assert_includes md, "**world**"
  end

  def test_converter_handles_nil
    converter = MyNews::Normalize::Converter.new
    assert_equal "", converter.convert(nil)
  end

  def test_converter_collapses_blank_lines
    converter = MyNews::Normalize::Converter.new
    html = "<p>One</p>\n\n\n\n<p>Two</p>"
    md = converter.convert(html)
    refute_includes md, "\n\n\n"
  end

  def test_extractor_extracts_article_content
    extractor = MyNews::Normalize::Extractor.new
    html = <<~HTML
      <html><body>
        <nav>Menu</nav>
        <article><p>Main content here</p></article>
        <footer>Footer</footer>
      </body></html>
    HTML
    result = extractor.send(:extract_readable, html)
    assert_includes result, "Main content"
    refute_includes result, "Menu"
    refute_includes result, "Footer"
  end

  def test_normalizer_creates_articles_from_entries
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    MyNews::Models::Entry.create(
      feed_id: feed.id,
      guid: "test-1",
      title: "Test Article",
      url: "https://example.com/1",
      raw_html: "<article><p>Some content here</p></article>",
      fetched_at: Time.now
    )

    normalizer = MyNews::Normalize::Normalizer.new
    count = normalizer.call

    assert_equal 1, count
    assert_equal 1, MyNews::Models::Article.count

    article = MyNews::Models::Article.first
    assert_includes article.markdown, "Some content here"
  end

  def test_normalizer_skips_already_processed
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Test")
    entry = MyNews::Models::Entry.create(
      feed_id: feed.id, guid: "test-1", title: "Test",
      raw_html: "<p>Content</p>", fetched_at: Time.now
    )
    MyNews::Models::Article.create(
      entry_id: entry.id, markdown: "Content", processed_at: Time.now
    )

    normalizer = MyNews::Normalize::Normalizer.new
    count = normalizer.call

    assert_equal 0, count
    assert_equal 1, MyNews::Models::Article.count
  end
end
