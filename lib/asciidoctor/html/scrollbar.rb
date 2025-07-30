# frozen_string_literal: true

module Asciidoctor
  module Html
    # Calculate scrollbar width and adjust divider position
    module Scrollbar
      ADJUST_SCROLL_BORDER = <<~JS
        (function() {
          const contentContainer = document.getElementById("content-container");
          const main = document.getElementById("main");
          const mainRect = main.getBoundingClientRect();
          const contentRect = contentContainer.getBoundingClientRect();
          const paddingLeft = contentRect.left
          const paddingRight = mainRect.right - contentRect.right;
          const scrollbarWidth = paddingRight - paddingLeft;
          if(scrollbarWidth == 0) return;

          const scrollBorder = document.getElementById("scroll-border");
          const sidebar = document.getElementById("sidebar");
          scrollBorder.style.display = "block"

          function repositionScrollBorder() {
            scrollBorder.style.right = (sidebar.offsetWidth + scrollbarWidth) + "px";
          }

          repositionScrollBorder();
          addEventListener("resize", repositionScrollBorder);
        })();
      JS
    end
  end
end
