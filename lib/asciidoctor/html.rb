# frozen_string_literal: true

module Asciidoctor
  # Constants in the Html namespace
  module Html
    ASSETS_PATH = "assets"
    FAVICON_PATH = "#{ASSETS_PATH}/favicon".freeze
    CSS_PATH = "#{ASSETS_PATH}/css".freeze
    IMG_PATH = "#{ASSETS_PATH}/img".freeze
    SEARCH_PAGE = "search.html"
    SEARCH_INDEX = "search-index.json"
  end
end

require_relative "html/converter"
require_relative "html/ref_tree_processor"
require_relative "html/book"
require_relative "html/cli"
