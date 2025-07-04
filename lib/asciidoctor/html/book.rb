# frozen_string_literal: true

require_relative "ref_tree_processor"

module Asciidoctor
  module Html
    # A book is a collection of documents with cross referencing
    # supported via the cref macro.
    class Book
      attr_reader :documents, :refs

      def initialize(documents)
        @documents = documents || []
        # refs becomes an array of hashes { refid => reftext },
        # with the hash at index i corresponding to the ith
        # document's refs.
        @refs = []
        process_refs
      end

      def process_refs
        rtprocessor = RefTreeProcessor.new
        @documents.each do |doc|
          rtprocessor.process(doc)
          @refs << doc.catalog[:refs].transform_values(&method(:reftext)).compact
        end
      end

      def reftext(node)
        node.reftext || (node.title unless node.inline?)
      end
    end
  end
end
