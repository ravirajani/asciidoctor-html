# frozen_string_literal: true

module Asciidoctor
  module Html
    # Flip when pagestyle=multipage
    module Flip
      FLIP = <<~JS
        (function() {
          const sectSelector = '.content-container > .section[id]';
          // Holds replaced pagination links to prev/next chapter
          const chapPagination = {
            prevChap: null,
            nextChap: null
          };

          function updatePaginator(el) {
            const paginator = document.querySelector('.paginator');
            const nextPage = paginator.lastElementChild;
            const prevPage = paginator.firstElementChild;
            const next = el.nextElementSibling;
            const prev = el.previousElementSibling;
            if(next && next.matches(sectSelector)) {
              const nextLink = document.createElement('a');
              nextLink.href = '#' + next.id;
              nextLink.innerHTML = 'Next &rsaquo;';
              chapPagination.nextChap ||= nextPage;
              nextPage.replaceWith(nextLink);
            } else if(chapPagination.nextChap) {
              nextPage.replaceWith(chapPagination.nextChap);
            }
            if(el.matches(sectSelector)) {
              const prevLink = document.createElement('a');
              prevLink.href = prev.id ? '#' + prev.id : '';
              prevLink.innerHTML = '&lsaquo; Prev';
              chapPagination.prevChap ||= prevPage;
              prevPage.replaceWith(prevLink);
            } else if(chapPagination.prevChap) {
              prevPage.replaceWith(chapPagination.prevChap)
            }
            paginator.classList.add('visible');
          }

          function flip(e) {
            e && e.preventDefault();

            const href = location.hash;
            const id = href.substring(1);
            const target = document.getElementById(id);

            document.querySelectorAll('.content-container > .chaphead, .content-container > .preamble').forEach(el => {
              el.classList.toggle('hidden', target);
            });
            const section = target && target.closest(sectSelector);
            section || updatePaginator(document.querySelector(sectSelector).previousElementSibling);
            section && document.querySelectorAll(sectSelector).forEach(el => {
              const hit = (el == section);
              el.classList.toggle('d-block', hit);
              hit && updatePaginator(el);
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
