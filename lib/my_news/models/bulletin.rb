# frozen_string_literal: true

module MyNews
  module Models
    class Bulletin < Sequel::Model
      set_dataset MyNews.db[:bulletins]
    end
  end
end
