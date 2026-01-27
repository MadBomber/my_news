# frozen_string_literal: true

module MyNews
  module Fetch
    module Handlers
      class Mastodon < Base
        # Mastodon feeds use Atom format. Posts may contain media
        # attachments referenced as enclosures. This handler extracts
        # those and appends them as image tags in the raw_html.
        def transform(item)
          data = super
          return nil unless data

          media_html = extract_media(item)
          if media_html
            data[:raw_html] = [data[:raw_html], media_html].compact.join("\n")
          end

          # Mastodon posts often lack titles; use first 80 chars of content
          if data[:title].nil? || data[:title].strip.empty?
            plain = (data[:raw_html] || "").gsub(/<[^>]+>/, "").strip
            data[:title] = plain[0, 80]
          end

          data
        end

        private

        def extract_media(item)
          return unless item.respond_to?(:enclosure) && item.enclosure

          url  = item.enclosure.url rescue nil
          type = item.enclosure.type rescue nil
          return unless url

          if type&.start_with?("image/")
            %(<p><img src="#{url}" alt="attached media" /></p>)
          elsif type&.start_with?("video/")
            %(<p><video src="#{url}" controls>attached video</video></p>)
          else
            %(<p><a href="#{url}">Attachment</a></p>)
          end
        end
      end
    end
  end
end
