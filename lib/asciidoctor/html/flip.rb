# frozen_string_literal: true

module Asciidoctor
  module Html
    # Flip when pagestyle=multipage
    module Flip
      FLIP = <<~JS
        (function() {
          const sectSelector = '.content-container > .section';
          // Holds replaced pagination links to prev/next chapter
          const chapPagination = {
            prevChap: null,
            nextChap: null
          };

          // Dictionary sect ID => [all sects until next sect with ID]
          const sectsById = { "page": []};

          const page = document.getElementById('page');

          const nav = document.querySelectorAll('#sidebar nav > ul > li.active > ul > li');

          let currentId = "page";
          document.querySelectorAll('.content-container > .chaphead, .content-container > .preamble').forEach(el => {
            sectsById[currentId].push(el);
            el.dataset.withSect = currentId;
          });
          document.querySelectorAll(sectSelector).forEach(el => {
            if(el.id) {
              el.dataset.prevPage = currentId;
              currentId = el.id;
              sectsById[currentId] ||= [];
            }
            const prevId = el.dataset.prevPage;
            if(prevId) {
              sectsById[prevId][0].dataset.nextPage = currentId;
            }
            sectsById[currentId].push(el);
            el.dataset.withSect = currentId;
          });

          function updatePaginator(prev, next) {
            const paginator = document.querySelector('.paginator');
            if(!paginator) return;
            const nextPage = paginator.lastElementChild;
            const prevPage = paginator.firstElementChild;
            if(next) {
              const nextLink = document.createElement('a');
              nextLink.href = '#' + next.id;
              nextLink.innerHTML = 'Next &rsaquo;';
              chapPagination.nextChap ||= nextPage;
              nextPage.replaceWith(nextLink);
            } else if(chapPagination.nextChap) {
              nextPage.replaceWith(chapPagination.nextChap);
            }
            if(prev) {
              const prevLink = document.createElement('a');
              prevLink.href = '#' + (prev.id ? prev.id : 'page');
              prevLink.innerHTML = '&lsaquo; Previous';
              chapPagination.prevChap ||= prevPage;
              prevPage.replaceWith(prevLink);
            } else if(chapPagination.prevChap) {
              prevPage.replaceWith(chapPagination.prevChap)
            }
            paginator.classList.add('visible');
          }

          function flip(e) {
            if(!page.classList.contains('multi')) return;

            e && e.preventDefault();

            const href = location.hash;
            let id = href.substring(1);
            const target = document.getElementById(id);

            if(!target) id = 'page';

            document.querySelector('.breadcrumb').classList.toggle('d-block', id != 'page');

            let section = target && target.closest(sectSelector);
            if(section) {
              id = section.dataset.withSect;
              section = sectsById[id][0];
            }

            for(const key in sectsById) {
              if(key == id) {
                const firstSect = sectsById[key][0];
                const prev = firstSect.dataset.prevPage && sectsById[firstSect.dataset.prevPage][0];
                const next = firstSect.dataset.nextPage && sectsById[firstSect.dataset.nextPage][0];
                updatePaginator(prev, next);
                sectsById[key].forEach(el => el.classList.add('d-block'));
              } else {
                sectsById[key].forEach(el => el.classList.remove('d-block'));
              }
            }

            nav.forEach(el => {
              const a = el.querySelector('a');
              const href = a && a.getAttribute('href');
              el.classList.toggle('active', id == href.substring(1));
            });

            ADHT.nudgeMenuBtn();

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

          const layoutButton = document.getElementById('btn-layout');
          layoutButton && layoutButton.addEventListener('click', function(){
            const multi = page.classList.contains('multi');
            layoutButton.textContent = (multi ? 'multiple pages' : 'single page');
            page.classList.toggle('multi');
            if(multi) {
              // We have switched to Single Page
              ADHT.nudgeMenuBtn();
              updatePaginator();
            } else {
              flip();
            }
          });
        })();
      JS
    end
  end
end
