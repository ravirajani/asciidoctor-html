# frozen_string_literal: true

require_relative "pagination"

module Asciidoctor
  module Html
    # Flip when pagestyle is multi or presentation
    module Flip
      FLIP = <<~JS.freeze
        (function() {
          // Holds replaced pagination links to prev/next chapter
          const chapPagination = {
            prevChap: null,
            nextChap: null
          };

          // Dictionary sect ID => [all sects until next sect with ID]
          const sectsById = { 'page': []};

          const page = document.getElementById('page');
          const main = document.getElementById('main');
          const focusEl = document.getElementById('content-container');
          const paginator = document.getElementById('paginator');
          const searchForm = document.getElementById('search-form');
          const chapheading = page.querySelector('.chapheading');
          const chaptitle = page.querySelector('.chaptitle');

          const nav = document.querySelectorAll('#sidebar nav > ul > li.active  ul  li');

          let scrollTop = {}; // cache scroll position by id
          let currentId = 'page';
          focusEl.querySelectorAll(':scope > .flip').forEach(el => {
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

          for(const sects of Object.values(sectsById)) {
            sects[sects.length - 1].classList.add('last-section-multipage');
          }

          function focusOnLoad() {
            if(searchForm) return;

            focusEl.focus({preventScroll: true});
          }

          function pagitemHTML(text, direction) {
            if(direction == 'left') {
              return `#{Pagination.pagitem_html "${text}", left: true}`;
            }
            return `#{Pagination.pagitem_html "${text}"}`;
          }

          function updatePaginator(prev, next) {
            if(!paginator) return;
            const nextPage = paginator.lastElementChild;
            const prevPage = paginator.firstElementChild;
            if(next) {
              const nextH = next.querySelector(':scope > h2');
              const nextLink = document.createElement('a');
              nextLink.id = 'flip-forward';
              const nextSectText = nextH && nextH.innerHTML;
              nextLink.href = '#' + next.id;
              nextLink.innerHTML = pagitemHTML(nextSectText, 'right');
              chapPagination.nextChap ||= nextPage;
              nextPage.replaceWith(nextLink);
            } else if(chapPagination.nextChap) {
              nextPage.replaceWith(chapPagination.nextChap);
            }
            if(prev) {
              const prevH = prev.querySelector(':scope > h2');
              const prevSectitle = prevH && (prevH.innerHTML + ' ');
              const prevLink = document.createElement('a');
              prevLink.id = 'flip-back';
              let prevSectText = prevSectitle || chapheading &&
                ('<span class="title-prefix">' + chapheading.textContent + '</span><br>') || '';
              if(!prevH) prevSectText += chaptitle.textContent;
              prevLink.href = '#' + (prev.id ? prev.id : 'page');
              prevLink.innerHTML = pagitemHTML(prevSectText, 'left');
              chapPagination.prevChap ||= prevPage;
              prevPage.replaceWith(prevLink);
            } else if(chapPagination.prevChap) {
              prevPage.replaceWith(chapPagination.prevChap);
            }
          }

          function getScrollEl() {
            return page.classList.contains('presentation') ? main : page;
          }

          currentId = null;

          async function flip(e) {
            e && e.preventDefault();
            const scrollEl = getScrollEl();

            const href = location.hash;
            let id = href.substring(1);
            let target = document.getElementById(id);

            if(!target) {
              id = 'page';
              target = page;
            }

            let section = target && target.closest('.content-container > .section');
            if(section) {
              id = section.dataset.withSect;
              section = sectsById[id][0];
            } else {
              id = 'page';
            }

            const needsFlip = (currentId !== id);

            const isPresentation = page.classList.contains('presentation');
            const isMulti = page.classList.contains('multi');
            document.querySelector('.breadcrumb').classList.toggle('d-block', id != 'page' && isMulti && !isPresentation);
            document.querySelector('.chapauthors').classList.toggle('d-block', isPresentation);

            let activeSects = [focusEl];
            if(isMulti && needsFlip) {
              page.classList.remove('loaded');
              for(const key in sectsById) {
                if(key == id) {
                  const firstSect = sectsById[key][0];
                  const prev = firstSect.dataset.prevPage && sectsById[firstSect.dataset.prevPage][0];
                  const next = firstSect.dataset.nextPage && sectsById[firstSect.dataset.nextPage][0];
                  updatePaginator(prev, next);
                  activeSects = sectsById[key];
                  activeSects.forEach(el => el.classList.add('d-block'));
                } else {
                  sectsById[key].forEach(el => el.classList.remove('d-block'));
                }
              }
            }

            nav.forEach(el => {
              const a = el.querySelector('a');
              a && a.hash && el.classList.toggle('active', id == a.hash.substring(1));
            });

            const typesetEls = paginator ? [...activeSects, paginator] : activeSects;
            // MathJax needs displayed content to calculate auto line breaks.
            await MathJax.startup.promise;
            await MathJax.typesetPromise(typesetEls);
            ADHT.nudgeMenuBtn();
            page.classList.add('loaded');

            if(target == section && page.classList.contains('multi') || target == page) {
              scrollEl.scrollTo({
                top: id in scrollTop ? scrollTop[id] : 0,
                left: 0,
                behavior: 'instant'
              });
            } else {
              const rect = target.getBoundingClientRect();
              const containerRect = scrollEl.getBoundingClientRect();
              scrollEl.scrollTo({
                top: rect.top + scrollEl.scrollTop - containerRect.top,
                left: 0
              });
            }

            focusOnLoad();
            if(isPresentation) focusEl.dataset.flip = id;
            currentId = id;
          }

          const dropdownItems = document.querySelectorAll('#viewmode-actions .dropdown-item');
          const dropdownToggle = document.getElementById('btn-toggle');
          function changeViewmode(viewmode) {
            page.classList.toggle('multi', viewmode == 'multi' || viewmode == 'presentation');
            page.classList.toggle('presentation', viewmode == 'presentation');
            if(viewmode == 'single') {
              updatePaginator();
            }
            currentId = null;
            scrollTop = {};
            flip();
            dropdownItems.forEach(el => {
              const isActive = (el.dataset.viewmode == viewmode);
              el.classList.toggle('active', isActive);
              if(isActive) dropdownToggle.textContent = el.textContent;
            });
          }
          function move(direction) {
            let link;
            if(direction == 'right' && (link = document.getElementById('flip-forward')))
              navigation.navigate(link.href);
            else if (direction == 'left' && (link = document.getElementById('flip-back')))
              navigation.navigate(link.href);
          }
          addEventListener('hashchange', flip);
          addEventListener('keyup', function(e) {
            switch(e.key) {
              case 'ArrowLeft': move('left'); break;
              case 'ArrowRight': move('right'); break;
              case 'q':
              case 'Escape':
                page.classList.contains('presentation') && changeViewmode('multi');
            }
          });
          document.querySelectorAll('a').forEach(el => {
            el.addEventListener('click', () => {
              const scrollEl = getScrollEl();
              if(currentId) {
                scrollTop[currentId] = scrollEl.scrollTop;
              }
            });
          });

          const clickableHSelector = [2, 3, 4].map(v => `section[id] > h${v}:first-child`).join(', ');
          document.querySelectorAll(clickableHSelector).forEach(el => {
            el.addEventListener('click', function() {
              location.hash = el.parentElement.id;
            });
          });

          dropdownItems && dropdownItems.forEach(link => link.addEventListener('click', function(e){
            e.preventDefault();
            const viewmode = link.dataset.viewmode;
            changeViewmode(viewmode);
          }));

          flip();

          ADHT.move = move;
        })();
      JS
    end
  end
end
