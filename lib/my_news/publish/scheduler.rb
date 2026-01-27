# frozen_string_literal: true

require "rufus-scheduler"
require "debug_me"

module MyNews
  module Publish
    class Scheduler
      include DebugMe

      def initialize(config: MyNews.config)
        @config    = config
        @times     = config.schedule_times
        @timezone  = config.schedule_timezone
        @scheduler = Rufus::Scheduler.new
      end

      def start
        debug_me "Starting scheduler (timezone: #{@timezone})"

        @times.each do |time|
          cron = "#{parse_minutes(time)} #{parse_hours(time)} * * *"
          debug_me "Scheduling pipeline at #{time} (cron: #{cron})"

          @scheduler.cron(cron, timezone: @timezone) do
            run_pipeline
          end
        end

        debug_me "Scheduler running. Press Ctrl-C to stop."
        @scheduler.join
      rescue Interrupt
        debug_me "Scheduler stopped."
        @scheduler.shutdown
      end

      def stop
        @scheduler.shutdown
      end

      private

      def run_pipeline
        debug_me "Pipeline triggered at #{Time.now}"

        Fetch::Fetcher.new.call
        Normalize::Normalizer.new.call
        Summarize::Summarizer.new.call
        Cluster::Deduplicator.new.call
        Cluster::Recurrence.new.call
        Publisher.new(config: @config).call

        debug_me "Pipeline completed at #{Time.now}"
      rescue => e
        debug_me "Pipeline error: #{e.message}"
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
