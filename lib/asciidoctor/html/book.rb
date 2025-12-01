# frozen_string_literal: true

require "pathname"
require "erb"
require "date"
require "asciidoctor"
require_relative "converter"
require_relative "ref_tree_processor"
require_relative "cref_inline_macro"
require_relative "bi_inline_macro"
require_relative "text_inline_macro"
require_relative "template"
require_relative "pagination"
require_relative "search"
require_relative "utils"

module Asciidoctor
  module Html
    # A book is a collection of documents with cross referencing
    # supported via the cref macro.
    class Book
      attr_reader :title, :chapname, :refs, :templates

      Asciidoctor::Extensions.register do
        tree_processor RefTreeProcessor
        inline_macro CrefInlineMacro
        inline_macro TextInlineMacro
        inline_macro BiInlineMacro
      end

      DOCATTRS = {
        "sectids" => false,
        "stem" => "latexmath",
        "hide-uri-scheme" => true,
        "source-highlighter" => "highlight.js",
        "imagesdir" => IMG_PATH,
        "dollar" => "&#36;",
        "parskip" => %(<span class="parskip"></span><br>)
      }.freeze

      DEFAULT_OPTS = {
        title: "Untitled Book",
        chapname: "Chapter"
      }.freeze

      # Template data to be processed by each document
      TData = Struct.new("TData",
                         :chapprefix,
                         :chaptitle,
                         :chapheading,
                         :chapsubheading,
                         :index)

      # opts:
      # - title
      # - short_title
      # - authors
      # - chapname
      def initialize(opts = {})
        opts = DEFAULT_OPTS.merge opts
        @title = ERB::Escape.html_escape opts[:title]
        @short_title = ERB::Escape.html_escape opts[:short_title]
        @authors = opts[:authors]
        @base_url = opts[:base_url]
        @chapname = opts[:chapname]
        @search_index = {} # Hash(docname => Array[SearchData])
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
      def write(chapters, appendices, outdir, sitemap: false)
        needs_sitemap = sitemap && @base_url
        entries = [] # for sitemap
        read(chapters, appendices).each do |name, html|
          filename = "#{name}.html"
          File.write("#{outdir}/#{filename}", html)
          build_index(name, html) unless omit_search?
          entries << Template.sitemap_entry("#{@base_url}#{filename}") if needs_sitemap
        end
        File.write "#{outdir}/#{SEARCH_PAGE}", search_page unless omit_search?
        File.write("#{outdir}/sitemap.xml", Template.sitemap(entries)) if needs_sitemap
      end

      private

      include Pagination
      include Search

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
        key = key filename
        index = @templates.dig(key, :index) || idx
        chapnum = index.to_s
        doc = parse_file filename, @chapname, chapnum
        chapsubheading = doctitle doc
        chapref = index.zero? ? chapsubheading : chapref_default(@chapname, chapnum)
        tdata = TData.new(
          chapprefix: index.zero? ? "" : chapnum,
          chaptitle: chapsubheading,
          chapheading: (chapref unless index.zero?),
          chapsubheading:,
          index:
        )
        process_doc key, doc, tdata, chapref
      end

      def appendix(filename, idx, num_appendices)
        key = key filename
        index = @templates.dig(key, :index) || idx
        chapname = "Appendix"
        chapnum = ("a".."z").to_a[index].upcase
        doc = parse_file filename, chapname, chapnum
        chapsubheading = doctitle doc
        chapref = num_appendices == 1 ? chapname : chapref_default(chapname, chapnum)
        tdata = TData.new(
          chapprefix: "",
          chaptitle: Template.appendix_title(chapname, chapnum, chapsubheading, num_appendices),
          chapheading: chapref,
          chapsubheading:,
          index:
        )
        process_doc key, doc, tdata, chapref
      end

      def key(filename)
        Pathname(filename).basename.sub_ext("").to_s
      end

      def process_doc(key, doc, tdata, chapref)
        val = doc.catalog[:refs].transform_values(&method(:reftext)).compact
        val["chapref"] = chapref
        @refs[key] = val
        @templates[key] = tdata
        doc
      end

      def parse_file(filename, chapname, chapnum)
        attributes = { "chapnum" => chapnum, "chapname" => chapname }.merge DOCATTRS
        Asciidoctor.load_file filename, safe: :unsafe, attributes:
      end

      def chapref_default(chapname, chapnum)
        "#{ERB::Escape.html_escape chapname} #{chapnum}"
      end

      def reftext(node)
        node.reftext || (node.title unless node.inline?) || "[#{node.id}]" if node.id
      end

      def display_authors(doc = nil)
        authors = []
        if doc
          authors = doc.authors.map do |author|
            doc.sub_replacements author.name
          end
        end
        if authors.empty? && @authors
          authors = @authors.map do |author|
            ERB::Escape.html_escape author
          end
        end
        return if authors.empty?

        [
          authors[0..-2].join(", "),
          authors[-1]
        ].reject(&:empty?).join(" and ")
      end

      def outline(doc)
        items = []
        doc.sections.each do |section|
          next unless section.id && section.level == 1

          prefix = Utils.display_sectnum(section) if section.numbered
          items << Template.nav_item("##{section.id}", "#{prefix}#{section.title}")
        end
        items.size > 1 ? "<ul>#{items.join "\n"}</ul>" : ""
      end

      def html(docs)
        html = {} # Hash(docname => html)
        docs.each do |key, doc|
          html[key] = build_template key, doc
        end
        html
      end

      def omit_search?
        @templates.size < 2 && @search_index.empty?
      end

      def nav_items(active_key = -1, doc = nil)
        items = @templates.map do |k, td|
          active = (k == active_key)
          subnav = active && doc ? outline(doc) : ""
          navtext = Template.nav_text td.chapprefix, td.chaptitle
          Template.nav_item "#{k}.html", navtext, subnav, active:
        end
        return items if omit_search?

        items.unshift(Template.nav_item(
                        SEARCH_PAGE,
                        %(<i class="bi bi-search"></i> Search),
                        active: (active_key == -1)
                      ))
      end

      def build_template(key, doc)
        tdata = @templates[key]
        nav_items = nav_items key, doc
        content = "#{ERB.new(doc.convert).result(binding)}\n#{pagination key}"
        Template.html(
          content,
          nav_items,
          title: @title,
          short_title: @short_title,
          authors: display_authors(doc),
          date: @date,
          description: doc.attr("description"),
          chapheading: tdata.chapheading,
          chapsubheading: tdata.chapsubheading,
          langs: langs(doc)
        )
      end
    end
  end
end
