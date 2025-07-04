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

      def test_refs_initialized
        assert_equal "Welcome", @book.refs["index"]["doctitle"]
        assert_equal "A Section", @book.refs["index"]["welcome-section"]
        assert_equal "Theorem 1.1", @book.refs["01-introduction"]["thm-intro"]
        assert_equal "A List", @book.refs["01-introduction"]["simple-list"]
        assert_equal "2(a)", @book.refs["01-introduction"]["simple-list-item"]
      end

      def test_docs_initialized
        @book.docs.each do |key, value|
          assert_equal value, File.read("#{__dir__}/_book/#{key}.rhtml")
        end
      end
    end
  end
end
