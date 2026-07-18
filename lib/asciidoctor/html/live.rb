# frozen_string_literal: true

module Asciidoctor
  module Html
    # Script for live presentations
    module Live
      LIVE = <<~JS
        (function() {
          console.log("live blocks detected");
        })();
      JS
    end
  end
end
