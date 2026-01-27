# frozen_string_literal: true

module MyNews
  module Models
    class Article < Sequel::Model
      set_dataset MyNews.db[:articles]
      many_to_one :entry, class: "MyNews::Models::Entry"
    end
  end
end
