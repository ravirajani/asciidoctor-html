# frozen_string_literal: true

require "test_helper"
require "pathname"

module Asciidoctor
  module Html
    # Tests the Book generator
    class TestBook < Minitest::Test
      def setup
        filenames = ["index.adoc", "01-introduction.adoc"].map { |f| "#{__dir__}/_book/#{f}" }
        @book = Book.new filenames, "Lecture"
      end

      def test_first_refs_initialized
        assert_equal "Welcome", @book.refs["index"]["chapref"]
        assert_equal 0, @book.refs["index"]["chapnum"]
        assert_equal "Welcome", @book.refs["index"]["chaptitle"]
        assert_equal "A Section", @book.refs["index"]["welcome-section"]
      end

      def test_second_refs_initialized
        assert_equal "Introduction", @book.refs["01-introduction"]["chaptitle"]
        assert_equal 1, @book.refs["01-introduction"]["chapnum"]
        assert_equal "Lecture 1", @book.refs["01-introduction"]["chapref"]
        assert_equal "Theorem 1.1", @book.refs["01-introduction"]["thm-intro"]
        assert_equal "Other Section", @book.refs["01-introduction"]["sec-other"]
        assert_equal "Lemma 1.2", @book.refs["01-introduction"]["lem-important"]
        assert_equal "A List", @book.refs["01-introduction"]["simple-list"]
        assert_equal "2(a)", @book.refs["01-introduction"]["simple-list-item"]
      end

      def test_docs_initialized
        @book.docs.each do |key, value|
          assert_equal value, File.read("#{__dir__}/_book/#{key}.html")
        end
      end
    end
  end
end
