# frozen_string_literal: true

module Asciidoctor
  module Html
    # Toggle behaviour of sidebar
    module Sidebar
      TOGGLE = <<~JS
        ADHT.nudgeMenuBtn = function() {
          const menuBtn = document.getElementById('menu-btn');
          if(!menuBtn) return;
          // Nudge menuBtn in case there is a scrollbar
          const main = document.getElementById('main');
          const scrollbarWidth = page.offsetWidth - main.offsetWidth;
          menuBtn.animate(
            { transform: 'translateX(' + (-scrollbarWidth) + 'px)' },
            { fill: 'forwards', duration: 150 }
          );
          // Cache scrollbar width
          ADHT.scrollbarWidth = scrollbarWidth
          return menuBtn;
        };
        (function() {
          const page = document.getElementById('page');
          const sidebar = document.getElementById('sidebar');
          const dismissBtn = document.getElementById('sidebar-dismiss-btn');
          function hideSidebar() {
            sidebar && sidebar.classList.remove('shown');
            page.classList.remove('noscroll');
          }

          // Sidebar should be hidden on any local link click
          document.querySelectorAll('a[href^="#"]').forEach(el => {
            el.addEventListener('click', hideSidebar);
          });
          addEventListener('resize', hideSidebar);
          dismissBtn && dismissBtn.addEventListener('click', hideSidebar);

          const menuBtn = ADHT.nudgeMenuBtn()
          if(!menuBtn) return;
          // Add click listener to toggle sidebar
          menuBtn.addEventListener('click', function() {
            sidebar && sidebar.classList.toggle('shown');
            if(ADHT.scrollbarWidth > 0) page.classList.toggle('noscroll');
          });
        })();
      JS
    end
  end
end
