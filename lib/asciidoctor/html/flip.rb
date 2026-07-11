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
            if(!page.classList.contains('multi')) return;

            e && e.preventDefault();

            const href = location.hash;
            let id = href.substring(1);
            const target = document.getElementById(id);

            if(!target) id = 'page';

            document.querySelector('.breadcrumb').classList.toggle('d-block', id != 'page' && !page.classList.contains('presentation'));

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
              let href = '#page';
              if(direction == 'left') {
                const prevLi = activeSubLi && activeSubLi.previousElementSibling ||
                  !activeSubLi && activeTopLevelLi.previousElementSibling;
                if(prevLi) href = prevLi.firstElementChild.href;
              } else if(direction == 'right') {
                const nextLi = !activeSubLi &&
                  (page.classList.contains('multi') && activeTopLevelLi.querySelector('ul > li') ||
                    activeTopLevelLi.nextElementSibling) ||
                  activeSubLi &&
                  (activeSubLi.nextElementSibling || activeTopLevelLi.nextElementSibling) ||
                  activeSubLi || activeTopLevelLi;
                href = nextLi.firstElementChild.href;
              }
              navigation.navigate(href);
          }
          addEventListener('hashchange', flip);
          addEventListener('keyup', function(e) {
            switch(e.key) {
              case 'ArrowLeft': move('left'); break;
              case 'ArrowRight': move('right'); break;
              case 'Escape': page.classList.contains('presentation') && changeViewmode('multi');
            }
          });

          dropdownItems && dropdownItems.forEach(link => link.addEventListener('click', function(e){
            e.preventDefault();
            const viewmode = link.dataset.viewmode;
            changeViewmode(viewmode);
          }));
        })();
      JS
    end
  end
end
