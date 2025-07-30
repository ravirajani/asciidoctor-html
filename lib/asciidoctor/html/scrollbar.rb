# frozen_string_literal: true

module Asciidoctor
  module Html
    # Calculate scrollbar width and adjust divider position
    module Scrollbar
      SCROLL_BORDER = <<~JS
        (function() {
          const contentContainer = document.getElementById("content-container");
          const main = document.getElementById("main");
          const mainRect = main.getBoundingClientRect();
          const contentRect = contentContainer.getBoundingClientRect();
          const paddingLeft = contentRect.left
          const paddingRight = mainRect.right - contentRect.right;
          const scrollbarWidth = paddingRight - paddingLeft;
          const sidebar = document.getElementById("sidebar");
          sidebar.classList.toggle("sb-visible", scrollbarWidth > 0);
        })();
      JS
    end
  end
end
