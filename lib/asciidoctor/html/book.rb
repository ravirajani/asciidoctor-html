# frozen_string_literal: true

require "pathname"
require "erb"
require "date"
require "asciidoctor"
require_relative "converter"
require_relative "ref_tree_processor"
require_relative "cref_inline_macro"
require_relative "template"
require_relative "utils"

module Asciidoctor
  module Html
    # A book is a collection of documents with cross referencing
    # supported via the cref macro.
    class Book
      attr_reader :docs, :refs, :langs, :title, :author, :date

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

      # Template data to be processed by each document
      TData = Struct.new("TData", :content, :nav, :chapnum, :chaptitle)

      def initialize(chapters = [INDEX], appendices = [], opts = {})
        chapters.unshift(INDEX) unless Pathname(chapters.first).basename.to_s == INDEX
        opts = DEFAULT_OPTS.merge opts, { appendices: 0 }
        @title = ERB::Escape.html_escape opts[:title]
        @author = ERB::Escape.html_escape opts[:author]
        @date = opts.include?(:date) ? Date.parse(opts[:date]) : Date.today
        @docs = {} # Hash(docname => converted_content)
        @refs = {} # Hash(docname => Hash(id => reftext))
        templates = {} # Hash(docname => TData)
        langs = {} # Hash(langname => true)
        chapters.each_with_index do |filename, idx|
          process_file! templates, langs, filename, idx, opts
        end
        opts[:appendices] = appendices.size
        appendices.each_with_index do |filename, idx|
          process_file! templates, langs, filename, idx, opts
        end
        @langs = langs.keys # Array[langname]
        generate_docs(templates)
      end

      private

      def process_file!(templates, langs, filename, idx, opts)
        chapname = opts[:chapname]
        numeral = idx.to_s
        num_appendices = opts[:appendices]
        if num_appendices.positive?
          chapname = "Appendix"
          numeral = num_appendices > 1 ? ("a".."z").to_a[idx].upcase : ""
        end
        attributes = { "chapnum" => numeral, "chapname" => chapname }.merge DOCATTRS
        doc = Asciidoctor.load_file(
          filename,
          safe: :unsafe,
          attributes:
        )
        langs.merge! doc.attr("source-langs") if doc.attr?("source-langs")
        doctitle = doc.doctitle sanitize: true, use_fallback: true
        key = Pathname(filename).basename.sub_ext("").to_s
        val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
        chapref = if (idx.positive? && num_appendices.zero?) || num_appendices > 1
                    "#{ERB::Escape.html_escape chapname} #{numeral}"
                  elsif num_appendices == 1
                    chapname
                  else
                    doctitle
                  end
        val["chapref"] = chapref
        @refs[key] = val
        templates[key] = TData.new(
          content: doc.convert,
          nav: outline(doc),
          chapnum: Template.chapnum(numeral, num_appendices),
          chaptitle: Template.chaptitle(chapname, numeral, doctitle, num_appendices)
        )
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

      def generate_docs(templates)
        templates.each do |key, tdata|
          nav_items = templates.map do |k, td|
            active = (k == key)
            subnav = active ? td.nav : ""
            navtext = Template.nav_text td.chapnum, td.chaptitle
            Template.nav_item("#{k}.html", navtext, subnav, active:)
          end
          content = ERB.new(tdata.content).result(binding)
          @docs[key] = Template.html(
            content,
            nav_items,
            title: @title,
            author: @author,
            date: @date,
            chapnum: tdata.chapnum,
            chaptitle: tdata.chaptitle,
            langs: @langs
          )
        end
      end
    end
  end
end
