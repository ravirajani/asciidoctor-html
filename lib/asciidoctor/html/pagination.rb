# frozen_string_literal: true

module Asciidoctor
  module Html
    # Mixin to add pagination support to Book class
    module Pagination
      # Pagination item
      PagItem = Struct.new "PagItem", :url, :title, :text

      def self.chevron(left: false)
        transform_attr = %( transform="rotate(180 7 8)") if left
        <<~HTML
          <svg xmlns="http://www.w3.org/2000/svg" width="100%" fill="currentColor" viewBox="3 0 8 16">
            <path#{transform_attr} fill-rule="evenodd" d="M6.776 1.553a.5.5 0 0 1 .671.223l3 6a.5.5 0 0 1 0 .448l-3 6a.5.5 0 1 1-.894-.448L9.44 8 6.553 2.224a.5.5 0 0 1 .223-.671"/>
          </svg>
        HTML
      end

      def self.pagitem_html(text, left: false)
        if left
          <<~HTML
            <div class="chevron">
              #{Pagination.chevron left:}
            </div>
            <div class="pagination-prv">#{text}</div>
          HTML
        else
          <<~HTML
            <div class="pagination-nxt">#{text}</div>
            <div class="chevron">
              #{Pagination.chevron}
            </div>
          HTML
        end
      end

      def self.display_prefix(prefix)
        %(<span class="title-prefix">#{prefix}</span><br>)
      end

      def display_paginator(prv, nxt)
        blank = %(<span class="blank">&nbsp;</span>)
        html = [<<~HTML
          <div class="paginator-wrapper">
          <div class="paginator dynamic-width">
        HTML
        ]
        html << if prv
                  prefix = Pagination.display_prefix(prv.title) if prv.title
                  text = "#{prefix}#{prv.text}"
                  <<~HTML
                    <a id="flip-back" href="#{prv.url}">
                      #{Pagination.pagitem_html text, left: true}
                    </a>
                  HTML
                else
                  blank
                end
        html << if nxt
                  prefix = Pagination.display_prefix(nxt.title) if nxt.title
                  text = "#{prefix}#{nxt.text}"
                  <<~HTML
                    <a id="flip-forward" href="#{nxt.url}">
                      #{Pagination.pagitem_html text}
                    </a>
                  HTML
                else
                  blank
                end
        html << %(</div></div>)
        html.join("\n")
      end

      def prv_nxt(keys, idx)
        pagitems = []
        [idx - 1, idx + 1].each do |i|
          if i.between?(0, keys.size - 1)
            key = keys[i]
            tdata = @templates[key]
            pagitems << PagItem.new(
              url: "#{key}.html",
              title: tdata[:chapheading],
              text: tdata[:chapsubheading]
            )
          else
            pagitems << nil
          end
        end
        display_paginator(*pagitems)
      end

      def pagination(key = -1)
        keys = @refs.keys
        idx = keys.find_index key
        return "" unless idx

        prv_nxt keys, idx
      end
    end
  end
end
