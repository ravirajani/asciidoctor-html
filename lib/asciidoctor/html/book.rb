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
      attr_reader :title, :author, :date, :chapname,
                  :refs, :templates

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
      TData = Struct.new("TData", :chapnum, :chaptitle)

      def initialize(opts = {})
        opts = DEFAULT_OPTS.merge opts
        @title = ERB::Escape.html_escape opts[:title]
        @author = ERB::Escape.html_escape opts[:author]
        @date = opts.include?(:date) ? Date.parse(opts[:date]) : Date.today
        @chapname = opts[:chapname]
        @refs = {} # Hash(docname => Hash(id => reftext))
        @templates = {} # Hash(docname => TData)
      end

      # params:
      # - chapters: array of filenames
      # - appendices: array of filenames
      # returns: Hash(file_basename_without_ext => html)
      def read(chapters = [], appendices = [])
        docs = {} # Hash(docname => document)
        chapters.each_with_index do |filename, idx|
          doc = chapter filename, idx
          register! docs, filename, doc
        end
        appendices.each_with_index do |filename, idx|
          doc = appendix filename, idx, appendices.size
          register! docs, filename, doc
        end
        html docs
      end

      # params:
      # - chapters: array of filenames
      # - appendices: array of filenames
      # - outdir: directory to write the converted html files to
      def write(chapters, appendices, outdir)
        read(chapters, appendices).each do |name, html|
          File.write("#{outdir}/#{name}.html", html)
        end
      end

      private

      def register!(docs, filename, doc)
        key = key filename
        docs[key] = doc
      end

      def langs(doc)
        doc.attr?("source-langs") ? doc.attr("source-langs").keys : []
      end

      def doctitle(doc)
        doc.doctitle sanitize: true, use_fallback: true
      end

      def chapter(filename, idx)
        numeral = idx.to_s
        doc = parse_file filename, @chapname, numeral
        chaptitle = doctitle doc
        chapref = idx.zero? ? chaptitle : chapref_default(@chapname, numeral)
        chapnum = idx.zero? ? "" : numeral
        process_doc key(filename), doc, chapnum:, chaptitle:, chapref:
      end

      def appendix(filename, idx, num_appendices)
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
        val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
        val["chapref"] = opts[:chapref]
        @refs[key] = val
        @templates[key] = TData.new(
          chapnum: opts[:chapnum],
          chaptitle: opts[:chaptitle]
        )
        doc
      end

      def parse_file(filename, chapname, numeral)
        attributes = { "chapnum" => numeral, "chapname" => chapname }.merge DOCATTRS
        Asciidoctor.load_file filename, safe: :unsafe, attributes:
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

      def html(docs)
        html = {} # Hash(docname => html)
        docs.each do |key, doc|
          html[key] = build_template key, doc
        end
        html
      end

      def build_template(key, doc)
        tdata = @templates[key]
        nav_items = @templates.map do |k, td|
          active = (k == key)
          subnav = active ? outline(doc) : ""
          navtext = Template.nav_text td.chapnum, td.chaptitle
          Template.nav_item "#{k}.html", navtext, subnav, active:
        end
        content = ERB.new(doc.convert).result(binding)
        Template.html(
          content,
          nav_items,
          title: @title,
          author: @author,
          date: @date,
          chapnum: tdata.chapnum,
          chaptitle: tdata.chaptitle,
          langs: langs(doc)
        )
      end
    end
  end
end
