# frozen_string_literal: true

require "test_helper"

module Asciidoctor
  class TestHtml < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil Asciidoctor::Html::VERSION
    end
  end
end
