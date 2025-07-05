# frozen_string_literal: true

require "pathname"
require "erb"
require "asciidoctor"
require_relative "converter"
require_relative "ref_tree_processor"
require_relative "cref_inline_macro"
require_relative "template"

module Asciidoctor
  module Html
    # A book is a collection of documents with cross referencing
    # supported via the cref macro.
    class Book
      attr_reader :docs, :refs, :navs

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
        @navs = {} # Hash(docname => converted_nav)
        erb_templates = {} # Hash(docname => erb_content)
        filenames.each_with_index do |filename, idx|
          attributes = { "chapnum" => idx }.merge DOCATTRS
          doc = Asciidoctor.load_file(
            filename,
            safe: :unsafe,
            attributes:
          )
          doctitle = ERB::Escape.html_escape doc.attr("doctitle")
          chapname = ERB::Escape.html_escape chapname
          key = Pathname(filename).basename.sub_ext("").to_s
          val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
          val["chaptitle"] = doctitle
          val["chapnum"] = idx
          val["chapref"] = idx.positive? ? "#{chapname} #{idx}" : doctitle
          @refs[key] = val
          erb_templates[key] = { content: doc.convert, nav: outline(doc) }
        end
        generate_docs(erb_templates)
      end

      def reftext(node)
        node.reftext || (node.title unless node.inline?) || "[#{node.id}]" if node.id
      end

      def outline(doc)
        items = []
        doc.sections.each do |section|
          next unless section.id && section.level == 1

          items << Template.nav_item("##{section.id}", section.title)
        end
        items.size > 1 ? Template.nav(items) : ""
      end

      def generate_docs(erb_templates)
        erb_templates.each do |key, hash|
          nav_items = erb_templates.map do |k, _h|
            active = (k == key)
            subnav = active ? hash[:nav] : ""
            icon = %(<i class="bi bi-chevron-#{active ? "down" : "right"}"></i>)
            navtext = %(#{icon}<span class="title-mark">#{@refs[k]["chapnum"]}</span>#{@refs[k]["chaptitle"]})
            Template.nav_item("#{k}.html", navtext, subnav, active:)
          end
          indent = " " * 12
          template = %(<main>\n<nav class="sidebar">
            #{Template.nav(nav_items)}
            </nav>
            <div class="content">
            <h2>#{@refs[key]["chaptitle"]}</h2>
            #{hash[:content]}
            </div>
            </main>
          ).gsub("\n#{indent}", "\n")
          erb = ERB.new template
          @docs[key] = erb.result(binding)
        end
      end
    end
  end
end
