# frozen_string_literal: true

module MyNews
  module Fetch
    module Handlers
      class Base
        attr_reader :feed

        def initialize(feed)
          @feed = feed
        end

        # Override in subclasses to transform raw RSS items before storage.
        # Receives a parsed RSS item, returns a Hash with keys:
        #   :guid, :title, :url, :raw_html
        # Return nil to skip the item.
        def transform(item)
          {
            guid:     extract_guid(item),
            title:    extract_title(item),
            url:      extract_link(item),
            raw_html: extract_content(item)
          }
        end

        # Override to provide custom HTTP headers for this feed.
        def extra_headers
          []
        end

        # Override to post-process the raw feed body before RSS parsing.
        def preprocess_body(body)
          body
        end

        private

        def extract_guid(item)
          if item.respond_to?(:guid) && item.guid
            item.guid.respond_to?(:content) ? item.guid.content : item.guid.to_s
          elsif item.respond_to?(:id) && item.id
            item.id.respond_to?(:content) ? item.id.content : item.id.to_s
          elsif item.respond_to?(:link)
            extract_link(item)
          else
            item.title.to_s
          end
        end

        def extract_title(item)
          return unless item.respond_to?(:title)

          item.title.respond_to?(:content) ? item.title.content : item.title.to_s
        end

        def extract_link(item)
          return unless item.respond_to?(:link)

          link = item.link
          if link.respond_to?(:href)
            link.href
          elsif link.respond_to?(:content)
            link.content
          else
            link.to_s
          end
        end

        def extract_content(item)
          if item.respond_to?(:content_encoded) && item.content_encoded
            item.content_encoded
          elsif item.respond_to?(:description) && item.description
            item.description.to_s
          elsif item.respond_to?(:content) && item.content
            item.content.respond_to?(:content) ? item.content.content : item.content.to_s
          end
        end
      end
    end
  end
end
