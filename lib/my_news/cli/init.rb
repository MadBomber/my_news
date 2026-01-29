# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "init", "Initialize ~/.config/my_news with default configuration"
    def init
      config_dir  = File.expand_path("~/.config/my_news")
      db_dir      = File.join(config_dir, "db")
      source_dir  = File.expand_path("../config", __dir__)

      FileUtils.mkdir_p(db_dir)

      files_to_copy = {
        "defaults.yml"   => "my_news.yml",
        "feeds.yml"      => "feeds.yml",
        "bulletins.yml"  => "bulletins.yml"
      }

      files_to_copy.each do |source_name, dest_name|
        source_path = File.join(source_dir, source_name)
        dest_path   = File.join(config_dir, dest_name)

        if File.exist?(dest_path)
          puts "Already exists: #{dest_path}"
        else
          FileUtils.cp(source_path, dest_path)
          puts "Created: #{dest_path}"
        end
      end

      puts <<~HEREDOC

        MyNews initialized at #{config_dir}
          Config:    #{config_dir}/my_news.yml
          Feeds:     #{config_dir}/feeds.yml
          Bulletins: #{config_dir}/bulletins.yml
          Database:  #{db_dir}/my_news.db

        Edit configuration files to customize settings.
        Run 'my_news fetch' to start.
      HEREDOC
    end
  end
end
