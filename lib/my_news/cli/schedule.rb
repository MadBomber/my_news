# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "schedule", "Run the full pipeline on a cron schedule (3x/day by default)"
    def schedule
      MyNews.setup
      config = MyNews.config
      puts <<~HEREDOC
        Starting scheduler (#{config.schedule_timezone})
        Schedule: #{config.schedule_times.join(", ")}
        Press Ctrl-C to stop.
      HEREDOC
      scheduler = Publish::Scheduler.new
      scheduler.start
      puts "Scheduler stopped."
    end
  end
end
