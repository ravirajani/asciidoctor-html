# frozen_string_literal: true

require "pathname"
require "asciidoctor"
require_relative "converter"
require_relative "ref_tree_processor"
require_relative "cref_inline_macro"

module Asciidoctor
  module Html
    # A book is a collection of documents with cross referencing
    # supported via the cref macro.
    class Book
      attr_reader :docs, :refs

      Asciidoctor::Extensions.register do
        tree_processor RefTreeProcessor
        inline_macro CrefInlineMacro
      end

      DOCATTRS = {
        "sectids" => false,
        "stem" => "latexmath",
        "hide-uri-scheme" => true
      }.freeze

      INDEX = "index.adoc"

      def initialize(filenames = [INDEX], chapname = "Chapter")
        filenames.unshift(INDEX) unless Pathname(filenames.first).basename.to_s == INDEX
        @docs = {} # Hash(docname => converted_content)
        @refs = {} # Hash(docname => Hash(id => reftext))
        filenames.each_with_index do |filename, idx|
          attributes = { "chapnum" => idx }.merge DOCATTRS
          doc = Asciidoctor.load_file(
            filename,
            safe: :unsafe,
            attributes:
          )
          doctitle = doc.attr("doctitle")
          key = Pathname(filename).basename.sub_ext("").to_s
          val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
          val["chaptitle"] = doctitle
          val["chapnum"] = idx
          val["chapref"] = idx.positive? ? "#{chapname} #{idx}" : doctitle
          @refs[key] = val
          @docs[key] = doc.convert
        end
      end

      def reftext(node)
        node.reftext || (node.title unless node.inline?) || "[#{node.id}]" if node.id
      end
    end
  end
end
