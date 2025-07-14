# frozen_string_literal: true

module Asciidoctor
  # Constants in the Html namespace
  module Html
    VERSION = "0.1.2"
    WWW_DIR = "www"
    ASSETS_PATH = "assets"
    CSS_PATH = "#{ASSETS_PATH}/css".freeze
    IMG_PATH = "#{ASSETS_PATH}/img".freeze
  end
end

require_relative "html/converter"
require_relative "html/ref_tree_processor"
require_relative "html/book"
require_relative "html/cli"
