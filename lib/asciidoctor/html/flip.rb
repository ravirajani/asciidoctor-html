# frozen_string_literal: true

module Asciidoctor
  module Html
    # Flip when pagestyle is multi or presentation
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
          const focusEl = document.getElementById('content-container');
          const searchForm = document.getElementById('search-form');
          const chapheading = page.querySelector('.chapheading');
          const chaptitle = page.querySelector('.chaptitle');

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

          for(const sects of Object.values(sectsById)) {
            sects[sects.length - 1].classList.add('last-section-multipage');
          }

          function focusOnLoad() {
            if(searchForm) return;

            focusEl.focus({preventScroll: true});
          }

          function updatePaginator(prev, next) {
            const paginator = document.querySelector('.paginator');
            if(!paginator) return;
            const nextPage = paginator.lastElementChild;
            const prevPage = paginator.firstElementChild;
            if(next) {
              const nextH = next.querySelector(':scope > h2');
              const nextLink = document.createElement('a');
              const nextSectText = nextH && nextH.innerHTML;
              nextLink.href = '#' + next.id;
              nextLink.innerHTML = `
                <div>${nextSectText || ''}</div>
                <div><i class="bi bi-chevron-compact-right"></i></div>
              `;
              chapPagination.nextChap ||= nextPage;
              nextPage.replaceWith(nextLink);
            } else if(chapPagination.nextChap) {
              nextPage.replaceWith(chapPagination.nextChap);
            }
            if(prev) {
              const prevH = prev.querySelector(':scope > h2');
              const prevSectitle = prevH && (prevH.innerHTML + ' ');
              const prevLink = document.createElement('a');
              let prevSectText = prevSectitle || chapheading &&
                ('<span class="title-prefix">' + chapheading.textContent + '</span><br>');
              if(!prevH) prevSectText += chaptitle.textContent;
              prevLink.href = '#' + (prev.id ? prev.id : 'page');
              prevLink.innerHTML = `
                <div><i class="bi bi-chevron-compact-left"></i></div>
                <div>${prevSectText || ''}</div>
              `;
              chapPagination.prevChap ||= prevPage;
              prevPage.replaceWith(prevLink);
            } else if(chapPagination.prevChap) {
              prevPage.replaceWith(chapPagination.prevChap)
            }
            paginator.classList.toggle('visible', paginator.querySelector('a'));
          }

          function flip(e) {
            if(!page.classList.contains('multi')) {
              focusOnLoad();
              return;
            }

            e && e.preventDefault();

            const href = location.hash;
            let id = href.substring(1);
            const target = document.getElementById(id);

            if(!target) id = 'page';

            const isPresentation = page.classList.contains('presentation');
            document.querySelector('.breadcrumb').classList.toggle('d-block', id != 'page' && !isPresentation);
            document.querySelector('.chapauthors').classList.toggle('d-block', isPresentation);

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
              a && a.hash && el.classList.toggle('active', id == a.hash.substring(1));
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

            focusOnLoad();
          }
          flip();

          const dropdownItems = document.querySelectorAll('#viewmode-actions .dropdown-item');
          const dropdownToggle = document.getElementById('btn-toggle');
          function changeViewmode(viewmode) {
            page.classList.toggle('multi', viewmode == 'multi' || viewmode == 'presentation');
            page.classList.toggle('presentation', viewmode == 'presentation');
            if(viewmode == 'single') {
              ADHT.nudgeMenuBtn();
              updatePaginator();
            } else {
              flip();
            }
            dropdownItems.forEach(el => {
              const isActive = (el.dataset.viewmode == viewmode);
              el.classList.toggle('active', isActive);
              if(isActive) dropdownToggle.textContent = el.textContent;
            });
          }
          function move(direction) {
              const activeTopLevelLi = document.querySelector('#sidebar nav > ul > li.active');
              if(!activeTopLevelLi) return;

              const activeSubLi = activeTopLevelLi.querySelector('ul > li.active');
              let nextLi = activeTopLevelLi;
              let url;
              if(direction == 'left') {
                if(activeSubLi){
                  if(nextLi = activeSubLi.previousElementSibling) {
                  } else {
                    url = '#page';
                  }
                } else if(nextLi = activeTopLevelLi.previousElementSibling) {
                  const lastChildLi = nextLi.querySelector('ul > li:last-child');
                  if(lastChildLi) nextLi = lastChildLi;
                } else {
                  url = '#page';
                }
              } else if(direction == 'right') {
                if(activeSubLi) {
                  nextLi = activeSubLi.nextElementSibling || activeTopLevelLi.nextElementSibling || activeSubLi;
                } else {
                  nextLi = page.classList.contains('multi') && activeTopLevelLi.querySelector('ul > li')
                    || activeTopLevelLi.nextElementSibling || activeSubLi || activeTopLevelLi;
                }
              }
              navigation.navigate(url || nextLi.firstElementChild.href);
          }
          addEventListener('hashchange', flip);
          addEventListener('keyup', function(e) {
            switch(e.key) {
              case 'ArrowLeft': move('left'); break;
              case 'ArrowRight': move('right'); break;
              case 'e':
              case 'Escape':
                page.classList.contains('presentation') && changeViewmode('multi');
            }
          });

          dropdownItems && dropdownItems.forEach(link => link.addEventListener('click', function(e){
            e.preventDefault();
            const viewmode = link.dataset.viewmode;
            changeViewmode(viewmode);
          }));

          page.classList.add('loaded');
        })();
      JS
    end
  end
end
