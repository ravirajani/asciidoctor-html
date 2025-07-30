# frozen_string_literal: true

module Asciidoctor
  module Html
    # Toggle behaviour of sidebar
    module Sidebar
      TOGGLE = <<~JS
        (function() {
          const sidebar = document.getElementById('sidebar');
          const menuBtn = document.getElementById('menu-btn');
          const dismissBtn = document.getElementById('sidebar-dismiss-btn');
          function hideSidebar() {
            sidebar && sidebar.classList.remove('shown');
          }
          menuBtn && menuBtn.addEventListener('click', function() {
            sidebar && sidebar.classList.toggle('shown');
          });
          addEventListener('hashchange', hideSidebar);
          addEventListener('resize', hideSidebar);
          dismissBtn && dismissBtn.addEventListener('click', hideSidebar);
        })();
      JS
    end
  end
end
