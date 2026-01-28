# frozen_string_literal: true

require "rufus-scheduler"

module MyNews
  module Publish
    class Scheduler
      def initialize(config: MyNews.config)
        @config    = config
        @times     = config.schedule_times
        @timezone  = config.schedule_timezone
        @scheduler = Rufus::Scheduler.new
      end

      def start
        @times.each do |time|
          cron = "#{parse_minutes(time)} #{parse_hours(time)} * * *"

          @scheduler.cron(cron, timezone: @timezone) do
            run_pipeline
          end
        end

        @scheduler.join
      rescue Interrupt
        @scheduler.shutdown
      end

      def stop
        @scheduler.shutdown
      end

      private

      def run_pipeline
        Fetch::Fetcher.new.call
        Normalize::Normalizer.new.call
        Summarize::Summarizer.new.call
        Cluster::Deduplicator.new.call
        Cluster::Recurrence.new.call
        Publisher.new(config: @config).call
      rescue => e
        # Pipeline error
      end

      def parse_hours(time_str)
        time_str.split(":").first.to_i
      end

      def parse_minutes(time_str)
        time_str.split(":").last.to_i
      end
    end
  end
end
