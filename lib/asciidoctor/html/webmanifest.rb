# frozen_string_literal: true

require "json"

module Asciidoctor
  module Html
    # Generates the site.webmanifest for Android
    module Webmanifest
      def self.generate(name, short_name)
        {
          name:,
          short_name:,
          icons: %w[192x192 512x512].map do |sizes|
            { src: "#{FAVICON_PATH}/android-chrome-#{sizes}.png", sizes:, type: "image/png" }
          end,
          theme_color: "#ffffff",
          background_color: "#ffffff",
          display: "standalone"
        }.to_json
      end
    end
  end
end
