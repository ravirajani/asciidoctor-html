# frozen_string_literal: true

module Asciidoctor
  module Html
    # Toggle behaviour of sidebar
    module Sidebar
      TOGGLE = <<~JS
        (function() {
          const page = document.getElementById('page');
          const sidebar = document.getElementById('sidebar');
          const dismissBtn = document.getElementById('sidebar-dismiss-btn');
          function hideSidebar() {
            sidebar && sidebar.classList.remove('shown');
            page.classList.remove('noscroll');
          }
          function clickLocalLink(e) {
            e.preventDefault();
            id = this.getAttribute('href').substring(1);
            target = document.getElementById(id);
            target && target.scrollIntoView();
          }
          function listenToLocalLink(link) {
            hideSidebar();
            href = link.getAttribute('href');
            if(href.startsWith('#')) {
              link.addEventListener('click', clickLocalLink);
            }
          }
          // Sidebar should be hidden on any link click
          // Also: custom handling of event due to mobile bugs
          document.querySelectorAll('a[href]').forEach(listenToLocalLink);
          addEventListener('resize', hideSidebar);
          dismissBtn && dismissBtn.addEventListener('click', hideSidebar);

          const menuBtn = document.getElementById('menu-btn');
          if(!menuBtn) return;

          // Nudge menuBtn in case there is a scrollbar
          const main = document.getElementById('main');
          const scrollbarWidth = page.offsetWidth - main.offsetWidth;
          menuBtn.style.right = (scrollbarWidth + 12) + 'px';

          // Add click listener to toggle sidebar
          menuBtn.addEventListener('click', function() {
            sidebar && sidebar.classList.toggle('shown');
            if(scrollbarWidth > 0) page.classList.toggle('noscroll');
          });
        })();
      JS
    end
  end
end
