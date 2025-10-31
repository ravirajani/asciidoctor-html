# frozen_string_literal: true

module Asciidoctor
  module Html
    # Due to mobile dynamic viewport heights, we need custom code for
    # reliable anchor scrolling.
    module Scroll
      SCROLL = <<~JS
        (function() {
          const page = document.getElementById('page');
          let scrolledOnce = false;
          function scrollToElement(e) {
            e && e.preventDefault();
            scrolledOnce = true;
            const href = location.hash;
            const id = href.substring(1);
            const target = document.getElementById(id);
            if(!target) return;

            const rect = target.getBoundingClientRect()
            page.scrollTo({
              top: rect.top + page.scrollTop,
              left: 0,
              behavior: 'smooth'
            });
          }
          addEventListener('hashchange', scrollToElement);
          addEventListener('load', function() {
            !scrolledOnce && scrollToElement();
          });
        })();
      JS
    end
  end
end
