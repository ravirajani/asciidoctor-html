# frozen_string_literal: true

require "test_helper"

module Asciidoctor
  module Html
    # Tests the Book generator
    module TestBook
      CHAPTERS = %w[index.adoc 01-introduction.adoc].map { |f| "#{__dir__}/_book/#{f}" }.freeze

      APPENDICES = %w[appendix-a.adoc appendix-b.adoc].map { |f| "#{__dir__}/_book/#{f}" }.freeze

      # Shared tests
      module Common
        def test_first_refs_initialized
          assert_equal "Welcome", @book.refs.dig("index", "chapref")
          assert_equal "A Section", @book.refs.dig("index", "welcome-section")
          assert_equal "Theorem 0.1", @book.refs.dig("index", "thm-welcome")
          assert_equal "Figure 0.1", @book.refs.dig("index", "img-cat")
        end

        def test_second_refs_initialized
          assert_equal "Lecture 1", @book.refs.dig("01-introduction", "chapref")
          assert_equal "Theorem 1.1", @book.refs.dig("01-introduction", "thm-intro")
          assert_equal "Other Section", @book.refs.dig("01-introduction", "sec-other")
          assert_equal "Lemma 1.2", @book.refs.dig("01-introduction", "lem-important")
          assert_equal "A List", @book.refs.dig("01-introduction", "simple-list")
          assert_equal "2(a)", @book.refs.dig("01-introduction", "simple-list-item")
        end

        def test_first_templates_initialized
          assert_equal "", @book.templates["index"]&.chapnum
          assert_equal "Welcome", @book.templates["index"]&.chaptitle
          assert_equal "1", @book.templates["01-introduction"]&.chapnum
          assert_equal "Book&#8217;s Introduction", @book.templates["01-introduction"]&.chaptitle
        end
      end

      class TestBookNoAppendix < Minitest::Test
        def setup
          @book = Book.new(
            title: "Test",
            chapname: "Lecture",
            author: "R. Rajani",
            date: "7/7/2025"
          )
          @book.read(CHAPTERS, [])
        end

        include Common

        def test_third_refs_initialized
          assert_nil @book.refs["appendix-a"]
        end
      end

      class TestBookOneAppendix < Minitest::Test
        def setup
          @book = Book.new(
            title: "Test",
            chapname: "Lecture",
            author: "R. Rajani",
            date: "7/7/2025"
          )
          @book.read(CHAPTERS, [APPENDICES.first])
        end

        include Common

        def test_third_refs_initialized
          assert_equal "Appendix", @book.refs.dig("appendix-a", "chapref")
          assert_equal "Example A.1", @book.refs.dig("appendix-a", "ex-appa")
        end

        def test_second_templates_initialized
          assert_equal "", @book.templates["appendix-a"]&.chapnum
          assert_equal %(<span class="title-prefix">Appendix</span>Linear Algebra Background),
                       @book.templates["appendix-a"]&.chaptitle
        end
      end

      class TestBookTwoAppendices < Minitest::Test
        def setup
          @book = Book.new(
            title: "Test",
            chapname: "Lecture",
            author: "R. Rajani",
            date: "7/7/2025"
          )
          @book.read(CHAPTERS, APPENDICES)
        end

        include Common

        def test_third_refs_initialized
          assert_equal "Appendix A", @book.refs.dig("appendix-a", "chapref")
          assert_equal "Appendix B", @book.refs.dig("appendix-b", "chapref")
          assert_equal "Example A.1", @book.refs.dig("appendix-a", "ex-appa")
          assert_equal "Other Results", @book.refs.dig("appendix-b", "sec-other")
        end

        def test_second_templates_initialized
          assert_equal "", @book.templates["appendix-a"]&.chapnum
          assert_equal %(<span class="title-prefix">Appendix A</span>Linear Algebra Background),
                       @book.templates["appendix-a"]&.chaptitle
          assert_equal "", @book.templates["appendix-b"]&.chapnum
          assert_equal %(<span class="title-prefix">Appendix B</span>Analysis Background),
                       @book.templates["appendix-b"]&.chaptitle
        end
      end
    end
  end
end
