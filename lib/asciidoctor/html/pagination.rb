# frozen_string_literal: true

module Asciidoctor
  module Html
    # Mixin to add pagination support to Book class
    module Pagination
      # Pagination item
      PagItem = Struct.new "PagItem", :url, :title, :text

      def display_paginator(prv, nxt)
        blank = %(<span class="blank">&nbsp;</span>)
        visible_class = " visible" if prv || nxt
        html = [<<~HTML
          <div class="paginator-wrapper">
          <div class="paginator#{visible_class}">
        HTML
        ]
        html << if prv
                  <<~HTML
                    <a href="#{prv.url}">
                      <div><i class="bi bi-chevron-compact-left"></i></div>
                      <div>#{"#{prv.title}<br>" if prv.title}#{prv.text}</div>
                    </a>
                  HTML
                else
                  blank
                end
        html << if nxt
                  <<~HTML
                    <a href="#{nxt.url}">
                      <div>#{"#{nxt.title}<br>" if nxt.title}#{nxt.text}</div>
                      <div><i class="bi bi-chevron-compact-right"></i></div>
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
