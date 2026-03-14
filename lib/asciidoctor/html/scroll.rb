# frozen_string_literal: true

module Asciidoctor
  module Html
    # Due to mobile dynamic viewport heights, we need custom code for
    # reliable anchor scrolling.
    module Scroll
      SCROLL = <<~JS
        (function() {
          let scrolledOnce = false;
          ADHT.scrollToElement = function(e) {
            e && e.preventDefault();
            scrolledOnce = true;
            const href = location.hash;
            const id = href.substring(1);
            const target = document.getElementById(id);
            if(!target) return;

            const rect = target.getBoundingClientRect()
            const page = document.getElementById('page');
            page.scrollTo({
              top: rect.top + page.scrollTop,
              left: 0,
              behavior: 'smooth'
            });
          }
          addEventListener('load', function() {
            !scrolledOnce && ADHT.scrollToElement();
          });
        })();
      JS
    end
  end
end
