# frozen_string_literal: true

module Asciidoctor
  module Html
    # Mixin to add pagination support to Book class
    module Pagination
      # Pagination item
      PagItem = Struct.new("PagItem", :url, :title)

      def display_paginator(prv, nxt)
        <<~HTML
          <div class="paginator-wrapper">
          <div class="d-inline-block">
          <div class="paginator">
            #{%(<a href="#{prv.url}">&laquo; #{prv.title}</a>) if prv}
            #{%(<span class="blank">&nbsp;</span>) unless prv && nxt}
            #{%(<a href="#{nxt.url}">#{nxt.title} &raquo;</a>) if nxt}
          </div>
          </div>
          </div>
        HTML
      end

      def prv_nxt(keys, idx)
        pagitems = []
        [idx - 1, idx + 1].each do |i|
          if i.between?(0, keys.size - 1)
            key = keys[i]
            ref = @refs[key]
            pagitems << PagItem.new(
              url: "#{key}.html",
              title: ref["chapref"]
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
