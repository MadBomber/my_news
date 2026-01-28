# frozen_string_literal: true

require "fileutils"

module MyNews
  module Publish
    class FileWriter
      def initialize(config: MyNews.config)
        @markdown_dir = config.markdown_dir
        @html_dir     = config.html_dir
      end

      def write(bulletin)
        timestamp = (bulletin.published_at || Time.now).strftime("%Y%m%d_%H%M")
        slug = "#{timestamp}_#{bulletin.theme}"

        write_file(@markdown_dir, "#{slug}.md", bulletin.content_md)
        write_file(@html_dir, "#{slug}.html", bulletin.content_html)
      end

      private

      def write_file(dir, filename, content)
        return unless content

        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, filename), content)
      end
    end
  end
end
