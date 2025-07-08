# frozen_string_literal: true

require "test_helper"
require "pathname"

module Asciidoctor
  module Html
    # Tests the Book generator
    module TestBook
      CHAPTERS = %w[index.adoc 01-introduction.adoc].map { |f| "#{__dir__}/_book/#{f}" }.freeze

      APPENDICES = %w[appendix-a.adoc appendix-b.adoc].map { |f| "#{__dir__}/_book/#{f}" }.freeze

      class TestBookNoAppendix < Minitest::Test
        def setup
          @book = Book.new(
            CHAPTERS,
            [],
            title: "Test",
            chapname: "Lecture",
            author: "R. Rajani",
            date: "7/7/2025"
          )
        end

        def test_first_refs_initialized
          assert_equal "Welcome", @book.refs["index"]["chapref"]
          assert_equal "A Section", @book.refs["index"]["welcome-section"]
        end

        def test_second_refs_initialized
          assert_equal "Lecture 1", @book.refs["01-introduction"]["chapref"]
          assert_equal "Theorem 1.1", @book.refs["01-introduction"]["thm-intro"]
          assert_equal "Other Section", @book.refs["01-introduction"]["sec-other"]
          assert_equal "Lemma 1.2", @book.refs["01-introduction"]["lem-important"]
          assert_equal "A List", @book.refs["01-introduction"]["simple-list"]
          assert_equal "2(a)", @book.refs["01-introduction"]["simple-list-item"]
        end

        def test_third_refs_initialized
          assert_nil @book.refs["appendix-a"]
        end

        def test_docs_initialized
          @book.docs.each do |key, value|
            assert_equal value, File.read("#{__dir__}/_book/#{key}.html")
          end
        end
      end

      class TestBookOneAppendix < Minitest::Test
        def setup
          @book = Book.new(
            CHAPTERS,
            [APPENDICES.first],
            title: "Test",
            chapname: "Lecture",
            author: "R. Rajani",
            date: "7/7/2025"
          )
        end

        def test_first_refs_initialized
          assert_equal "Welcome", @book.refs["index"]["chapref"]
          assert_equal "A Section", @book.refs["index"]["welcome-section"]
          assert_equal "Theorem 0.1", @book.refs["index"]["thm-welcome"]
          assert_equal "Figure 0.1", @book.refs["index"]["img-cat"]
        end

        def test_second_refs_initialized
          assert_equal "Lecture 1", @book.refs["01-introduction"]["chapref"]
          assert_equal "Theorem 1.1", @book.refs["01-introduction"]["thm-intro"]
          assert_equal "Other Section", @book.refs["01-introduction"]["sec-other"]
          assert_equal "Lemma 1.2", @book.refs["01-introduction"]["lem-important"]
          assert_equal "A List", @book.refs["01-introduction"]["simple-list"]
          assert_equal "2(a)", @book.refs["01-introduction"]["simple-list-item"]
        end

        def test_third_refs_initialized
          assert_equal "Appendix", @book.refs["appendix-a"]["chapref"]
          assert_equal "Example A.1", @book.refs["appendix-a"]["ex-appa"]
        end

        def test_docs_initialized
          @book.docs.each do |key, value|
            assert_equal value, File.read("#{__dir__}/_book/#{key}_2.html")
          end
        end
      end

      class TestBookTwoAppendices < Minitest::Test
        def setup
          @book = Book.new(
            CHAPTERS,
            APPENDICES,
            title: "Test",
            chapname: "Lecture",
            author: "R. Rajani",
            date: "7/7/2025"
          )
        end

        def test_first_refs_initialized
          assert_equal "Welcome", @book.refs["index"]["chapref"]
          assert_equal "A Section", @book.refs["index"]["welcome-section"]
          assert_equal "Theorem 0.1", @book.refs["index"]["thm-welcome"]
          assert_equal "Figure 0.1", @book.refs["index"]["img-cat"]
        end

        def test_second_refs_initialized
          assert_equal "Lecture 1", @book.refs["01-introduction"]["chapref"]
          assert_equal "Theorem 1.1", @book.refs["01-introduction"]["thm-intro"]
          assert_equal "Other Section", @book.refs["01-introduction"]["sec-other"]
          assert_equal "Lemma 1.2", @book.refs["01-introduction"]["lem-important"]
          assert_equal "A List", @book.refs["01-introduction"]["simple-list"]
          assert_equal "2(a)", @book.refs["01-introduction"]["simple-list-item"]
        end

        def test_third_refs_initialized
          assert_equal "Appendix A", @book.refs["appendix-a"]["chapref"]
          assert_equal "Appendix B", @book.refs["appendix-b"]["chapref"]
          assert_equal "Example A.1", @book.refs["appendix-a"]["ex-appa"]
          assert_equal "Other Results", @book.refs["appendix-b"]["sec-other"]
        end

        def test_docs_initialized
          @book.docs.each do |key, value|
            assert_equal value, File.read("#{__dir__}/_book/#{key}_3.html")
          end
        end
      end
    end
  end
end
