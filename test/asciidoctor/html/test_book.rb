# frozen_string_literal: true

require "test_helper"
require "pathname"

module Asciidoctor
  module Html
    # Tests the Book generator
    class TestBook < Minitest::Test
      def setup
        filenames = ["index.adoc", "01-introduction.adoc"].map { |f| "#{__dir__}/_book/#{f}" }
        @book = Book.new filenames
      end

      def test_initialized
        assert_equal "Welcome", @book.refs["index"]["doctitle"]
        assert_equal "Theorem 1.1", @book.refs["01-introduction"]["thm-intro"]
      end
    end
  end
end
