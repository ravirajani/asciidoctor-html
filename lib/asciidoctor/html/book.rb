# frozen_string_literal: true

require "pathname"
require "erb"
require "date"
require "asciidoctor"
require_relative "converter"
require_relative "ref_tree_processor"
require_relative "cref_inline_macro"
require_relative "bi_inline_macro"
require_relative "sc_inline_macro"
require_relative "template"
require_relative "pagination"

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
        inline_macro ScInlineMacro
        inline_macro BiInlineMacro
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
      TData = Struct.new("TData",
                         :chapprefix,
                         :chaptitle,
                         :chapheading,
                         :chapsubheading,
                         :index)

      # opts:
      # - title
      # - short_title
      # - author
      # - date
      # - se_id
      # - chapname
      def initialize(opts = {})
        opts = DEFAULT_OPTS.merge opts
        @title = ERB::Escape.html_escape opts[:title]
        @short_title = ERB::Escape.html_escape opts[:short_title]
        @author = ERB::Escape.html_escape opts[:author]
        @date = opts.include?(:date) ? Date.parse(opts[:date]) : Date.today
        @se_id = opts[:se_id]
        @base_url = opts[:base_url]
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
      def write(chapters, appendices, outdir, sitemap: false)
        needs_sitemap = sitemap && @base_url
        entries = [] # for sitemap
        read(chapters, appendices).each do |name, html|
          filename = "#{name}.html"
          File.write("#{outdir}/#{filename}", html)
          entries << Template.sitemap_entry("#{@base_url}#{filename}") if needs_sitemap
        end
        File.write("#{outdir}/#{SEARCH_PAGE}", search_page(@se_id)) if @se_id
        File.write("#{outdir}/sitemap.xml", Template.sitemap(entries)) if needs_sitemap
      end

      private

      include Pagination

      def search_page(se_id)
        content = <<~HTML
          <script async src="https://cse.google.com/cse.js?cx=#{se_id}"></script>
          <div class="gcse-search"></div>
        HTML
        Template.html(
          content,
          nav_items,
          title: @title,
          short_title: @short_title,
          author: @author,
          date: @date,
          chaptitle: "Search",
          langs: []
        )
      end

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

      def outline(doc)
        items = []
        doc.sections.each do |section|
          next unless section.id && section.level == 1

          items << Template.nav_item("##{section.id}", section.title)
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

      def nav_items(active_key = -1, doc = nil)
        items = @templates.map do |k, td|
          active = (k == active_key)
          subnav = active && doc ? outline(doc) : ""
          navtext = Template.nav_text td.chapprefix, td.chaptitle
          Template.nav_item "#{k}.html", navtext, subnav, active:
        end
        return items unless @se_id

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
          author: @author,
          date: @date,
          description: doc.attr("description"),
          chaptitle: tdata.chaptitle,
          chapheading: tdata.chapheading,
          chapsubheading: tdata.chapsubheading,
          langs: langs(doc)
        )
      end
    end
  end
end
