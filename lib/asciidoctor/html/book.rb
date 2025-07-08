# frozen_string_literal: true

require "pathname"
require "erb"
require "date"
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
        "imagesdir" => IMG_PATH
      }.freeze

      DEFAULT_OPTS = {
        title: "Untitled Book",
        author: "Anonymous Author",
        chapname: "Chapter"
      }.freeze

      # Template data to be processed by each document
      TData = Struct.new("TData", :content, :nav, :langs, :chapnum, :chaptitle)

      def initialize(chapters = ["index.adoc"], appendices = [], opts = {})
        opts = DEFAULT_OPTS.merge opts
        @title = ERB::Escape.html_escape opts[:title]
        @author = ERB::Escape.html_escape opts[:author]
        @date = opts.include?(:date) ? Date.parse(opts[:date]) : Date.today
        @docs = {} # Hash(docname => converted_content)
        @refs = {} # Hash(docname => Hash(id => reftext))
        @templates = {} # Hash(docname => TData)
        chapters.each_with_index do |filename, idx|
          process_chapter filename, idx, opts[:chapname]
        end
        appendices.each_with_index do |filename, idx|
          process_appendix filename, idx, appendices.size
        end
        generate_docs
      end

      private

      def doctitle(doc)
        doc.doctitle sanitize: true, use_fallback: true
      end

      def process_chapter(filename, idx, chapname)
        numeral = idx.to_s
        doc = parse_file filename, chapname, numeral
        chaptitle = doctitle doc
        chapref = idx.zero? ? chaptitle : chapref_default(chapname, numeral)
        chapnum = idx.zero? ? "" : numeral
        process_doc key(filename), doc, chapnum:, chaptitle:, chapref:
      end

      def process_appendix(filename, idx, num_appendices)
        chapname = "Appendix"
        numeral = ("a".."z").to_a[idx].upcase
        doc = parse_file filename, chapname, numeral
        chapref = num_appendices == 1 ? chapname : chapref_default(chapname, numeral)
        chapnum = ""
        chaptitle = Template.appendix_title chapname, numeral, doctitle(doc), num_appendices
        process_doc key(filename), doc, chapnum:, chaptitle:, chapref:
      end

      def key(filename)
        Pathname(filename).basename.sub_ext("").to_s
      end

      # opts:
      # - chapnum
      # - chaptitle
      # - chapref
      def process_doc(key, doc, opts)
        langs = doc.attr?("source-langs") ? doc.attr("source-langs").keys : []
        val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
        val["chapref"] = opts[:chapref]
        @refs[key] = val
        @templates[key] = TData.new(
          content: doc.convert,
          nav: outline(doc),
          langs:,
          chapnum: opts[:chapnum],
          chaptitle: opts[:chaptitle]
        )
      end

      def parse_file(filename, chapname, numeral)
        attributes = { "chapnum" => numeral, "chapname" => chapname }.merge DOCATTRS
        Asciidoctor.load_file(
          Pathname(filename).sub_ext(".adoc"),
          safe: :unsafe,
          attributes:
        )
      end

      def chapref_default(chapname, numeral)
        "#{ERB::Escape.html_escape chapname} #{numeral}"
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

      def generate_docs
        @templates.each_key do |key|
          generate_doc key
        end
      end

      def generate_doc(key)
        tdata = @templates[key]
        nav_items = @templates.map do |k, td|
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
          langs: tdata.langs
        )
      end
    end
  end
end
