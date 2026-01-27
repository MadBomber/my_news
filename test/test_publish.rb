# frozen_string_literal: true

require "test_helper"
require "fileutils"
StubOutputConfig = Struct.new(:markdown_dir, :html_dir, keyword_init: true)

class TestPublish < Minitest::Test
  include TestHelper

  def setup
    setup_test_db
    @tmpdir = File.join(Dir.tmpdir, "my_news_test_#{$$}")
    FileUtils.mkdir_p(@tmpdir)
    @md_dir   = File.join(@tmpdir, "markdown")
    @html_dir = File.join(@tmpdir, "html")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_bulletin_builder_creates_bulletins
    seed_articles_for_theme

    builder = MyNews::Publish::BulletinBuilder.new
    bulletins = builder.call

    refute_empty bulletins
    bulletin = bulletins.first
    assert_includes bulletin.content_md, "Bulletin"
    assert_includes bulletin.content_html, "<html>"
  end

  def test_file_writer_creates_files
    bulletin = MyNews::Models::Bulletin.create(
      theme: "tech",
      content_md: "# Tech\n\nHello",
      content_html: "<h1>Tech</h1><p>Hello</p>",
      published_at: Time.now
    )

    stub_config = StubOutputConfig.new(markdown_dir: @md_dir, html_dir: @html_dir)
    writer = MyNews::Publish::FileWriter.new(config: stub_config)
    writer.write(bulletin)

    md_files = Dir.glob(File.join(@md_dir, "*.md"))
    html_files = Dir.glob(File.join(@html_dir, "*.html"))

    assert_equal 1, md_files.size
    assert_equal 1, html_files.size
    assert_includes File.read(md_files.first), "Tech"
  end

  def test_scheduler_initializes_with_config
    scheduler = MyNews::Publish::Scheduler.new
    assert_instance_of MyNews::Publish::Scheduler, scheduler
    scheduler.stop
  end

  def test_freshrss_skips_when_not_configured
    bulletin = MyNews::Models::Bulletin.create(
      theme: "tech", content_md: "test", published_at: Time.now
    )

    # api_key is empty in defaults, so it should skip
    freshrss = MyNews::Publish::Freshrss.new
    freshrss.push(bulletin)

    refute bulletin.refresh.pushed_freshrss
  end

  private

  def seed_articles_for_theme
    feed = MyNews::Models::Feed.create(url: "https://example.com/rss", name: "Hacker News")
    entry = MyNews::Models::Entry.create(
      feed_id: feed.id, guid: "pub-1", title: "Ruby programming news",
      url: "https://example.com/1", fetched_at: Time.now
    )
    MyNews::Models::Article.create(
      entry_id: entry.id,
      markdown: "Ruby programming content about software development",
      summary: "A concise summary about ruby programming and software.",
      simhash: 12345,
      cluster_id: 1,
      processed_at: Time.now
    )
  end
end
