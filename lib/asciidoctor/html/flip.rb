# frozen_string_literal: true

module Asciidoctor
  module Html
    # Flip when pagestyle=multipage
    module Flip
      FLIP = <<~JS
        (function() {
          function flip(e) {
            e && e.preventDefault();

            const href = location.hash;
            const id = href.substring(1);
            const target = document.getElementById(id);

            document.querySelectorAll('.content-container > .chaphead, .content-container > .preamble').forEach(el => {
              el.classList.toggle('hidden', target);
            });
            const sect_selector = '.content-container > .section[id]';
            const section = target && target.closest(sect_selector);
            const paginator = document.querySelector('.paginator');
            section && document.querySelectorAll(sect_selector).forEach(el => {
              const hit = (el == section);
              el.classList.toggle('d-block', hit);
              if(hit) {
                const next = el.nextElementSibling;
                const prev = el.previousElementSibling;
                if(next && next.matches(sect_selector)) {
                  const nextLink = document.createElement('a');
                  nextLink.href = '#' + next.id;
                  nextLink.innerHTML = 'Next: &rsaquo;';
                  paginator.lastElementChild.replaceWith(nextLink);
                }
                if(prev && prev.matches(sect_selector)) {
                  console.log(prev.id);
                }
                paginator.classList.add('visible');
              }
            });

            ADHT.nudgeMenuBtn();

            if(!target) return;

            const page = document.getElementById('page');
            if(target == section) {
              page.scrollTo({
                top: 0,
                left: 0
              });
            } else {
              const rect = target.getBoundingClientRect()
              page.scrollTo({
                top: rect.top + page.scrollTop,
                left: 0
              });
            }
          }
          flip();
          addEventListener('hashchange', flip);
        })();
      JS
    end
  end
end
