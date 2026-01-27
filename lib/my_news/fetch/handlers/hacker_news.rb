# frozen_string_literal: true

module MyNews
  module Fetch
    module Handlers
      class HackerNews < Base
        # HN RSS items typically link to external URLs but include
        # a comments link. We store the external URL as the primary
        # link and append the HN comments link in the raw_html.
        def transform(item)
          data = super
          return nil unless data

          comments_url = extract_comments_url(item)
          if comments_url && data[:raw_html]
            data[:raw_html] += %(\n<p><a href="#{comments_url}">HN Discussion</a></p>)
          elsif comments_url
            data[:raw_html] = %(<p><a href="#{comments_url}">HN Discussion</a></p>)
          end

          data
        end

        private

        def extract_comments_url(item)
          if item.respond_to?(:comments) && item.comments
            item.comments.to_s
          elsif item.respond_to?(:guid) && item.guid
            guid = item.guid.respond_to?(:content) ? item.guid.content : item.guid.to_s
            guid if guid.include?("news.ycombinator.com")
          end
        end
      end
    end
  end
end
