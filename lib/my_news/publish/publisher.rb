# frozen_string_literal: true

require "debug_me"

module MyNews
  module Publish
    class Publisher
      include DebugMe

      def initialize(config: MyNews.config)
        @builder     = BulletinBuilder.new(config: config)
        @file_writer = FileWriter.new(config: config)
        @freshrss    = Freshrss.new(config: config)
      end

      def call
        bulletins = @builder.call
        return 0 if bulletins.empty?

        bulletins.each do |bulletin|
          @file_writer.write(bulletin)
          @freshrss.push(bulletin)
        end

        debug_me "Published #{bulletins.size} bulletins"
        bulletins.size
      end
    end
  end
end
