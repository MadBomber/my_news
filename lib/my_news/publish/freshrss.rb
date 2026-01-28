# frozen_string_literal: true

require "faraday"
require "digest"

module MyNews
  module Publish
    class Freshrss
      def initialize(config: MyNews.config)
        @url      = config.freshrss_url
        @username = config.freshrss_username
        @api_key  = config.freshrss_api_key
      end

      def push(bulletin)
        return unless configured?

        conn = Faraday.new(url: @url)
        api_password = Digest::MD5.hexdigest("#{@username}:#{@api_key}")

        response = conn.post do |req|
          req.params["api"] = ""
          req.body = {
            api_key:  api_password,
            mark:     "item",
            as:       "saved",
            id:       bulletin.id
          }
        end

        if response.success?
          bulletin.update(pushed_freshrss: true)
        end
      rescue => e
        # FreshRSS push error
      end

      private

      def configured?
        @url && !@url.empty? && @api_key && !@api_key.empty?
      end
    end
  end
end
