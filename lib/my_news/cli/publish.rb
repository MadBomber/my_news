# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "publish", "Build and publish themed bulletins"
    def publish
      MyNews.setup
      puts "Publishing bulletins..."
      publisher = Publish::Publisher.new
      count = publisher.call
      if count > 0
        puts "Published #{count} themed bulletins"
      else
        puts "No bulletins to publish"
      end
    end
  end
end
