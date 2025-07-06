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
      attr_reader :docs, :refs, :langs, :title, :author

      Asciidoctor::Extensions.register do
        tree_processor RefTreeProcessor
        inline_macro CrefInlineMacro
      end

      DOCATTRS = {
        "sectids" => false,
        "stem" => "latexmath",
        "hide-uri-scheme" => true,
        "source-highlighter" => "highlight.js",
        "imagesdir" => Template::IMG_PATH
      }.freeze

      DEFAULT_OPTS = {
        title: "Untitled Book",
        author: "Anonymous Author",
        chapname: "Chapter"
      }.freeze

      INDEX = "index.adoc"

      def initialize(filenames = [INDEX], opts = {})
        filenames.unshift(INDEX) unless Pathname(filenames.first).basename.to_s == INDEX
        opts = DEFAULT_OPTS.merge opts
        @title = ERB::Escape.html_escape opts[:title]
        @author = ERB::Escape.html_escape opts[:author]
        @docs = {} # Hash(docname => converted_content)
        @refs = {} # Hash(docname => Hash(id => reftext))
        templates = {} # Hash(docname => Hash)
        langs = {} # Hash(langname => true)
        filenames.each_with_index do |filename, idx|
          attributes = { "chapnum" => idx }.merge DOCATTRS
          doc = Asciidoctor.load_file(
            filename,
            safe: :unsafe,
            attributes:
          )
          langs.merge! doc.attr("source-langs") if doc.attr?("source-langs")
          doctitle = doc.doctitle sanitize: true, use_fallback: true
          chapname = ERB::Escape.html_escape opts[:chapname]
          key = Pathname(filename).basename.sub_ext("").to_s
          val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
          val["chapref"] = idx.positive? ? "#{chapname} #{idx}" : doctitle
          @refs[key] = val
          templates[key] = {
            content: doc.convert,
            nav: outline(doc),
            chapnum: idx,
            chaptitle: doctitle
          }
        end
        @langs = langs.keys # Array[String]
        generate_docs(templates)
      end

      private

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

      def generate_docs(templates)
        templates.each do |key, hash|
          nav_items = templates.map do |k, h|
            active = (k == key)
            subnav = active ? h[:nav] : ""
            icon = %(<i class="bi bi-chevron-#{active ? "down" : "right"}"></i>)
            navtext = %(#{icon}#{Template.nav_text h[:chapnum], h[:chaptitle]})
            Template.nav_item("#{k}.html", navtext, subnav, active:)
          end
          content = ERB.new(hash[:content]).result(binding)
          @docs[key] = Template.html(
            content,
            nav_items,
            title: @title,
            author: @author,
            chapnum: hash[:chapnum],
            chaptitle: hash[:chaptitle],
            langs: @langs
          )
        end
      end
    end
  end
end
