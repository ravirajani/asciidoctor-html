# frozen_string_literal: true

require "nokogiri"

module Asciidoctor
  module Html
    # Mixed in to Book class to provide full text search
    module Search
      SEARCH_RESULT_OVERFLOW = 10 # characters

      def search_page
        content = <<~HTML
          <div class="search-form-container">
            <form id="search-form" class="search-form">
              <input type="text" id="search-text" name="search-text" class="form-control search-box" placeholder="Search">
              <button type="submit" class="btn btn-primary search-btn">Go</button>
            </form>
          </div>
          <div id="search-results-container" class="hidden">
          <h4>Found <span id="search-nmatches">0 matches</span></h4>
          <ul id="search-results" class="search-results list-group list-group-flush"></ul>
          </div>
          <script src="https://unpkg.com/lunr/lunr.js"></script>
          <script>#{lunr_script}</script>
        HTML
        Template.html(
          content,
          nav_items,
          title: @title,
          short_title: @short_title,
          authors: display_authors,
          date: @date,
          chapsubheading: "Search",
          langs: []
        )
      end

      def build_index(key, html)
        doctree = Nokogiri::HTML5.parse html
        ref = @refs[key]
        page_text = "#{doctree.at_css(".chaptitle")&.text} #{doctree.at_css(".preamble")&.text}"
        index = [{
          id: "#{key}.html",
          title: ref["chapref"],
          text: page_text
        }]
        doctree.css("section[id]").each do |section|
          sectid = section["id"]
          id = "#{key}.html##{sectid}"
          title = "#{ref["chapref"]} › #{ref[sectid]}"
          text = section.text
          index << { id:, title:, text: }
        end
        @search_index[key] = index
      end

      def search_json
        index_arr = []
        @search_index.each_value do |search_data|
          index_arr.concat search_data
        end
        index_arr.to_json
      end

      def lunr_script
        <<~JS
          (function() {
            const resultsContainer = document.getElementById('search-results-container');
            const nmatches = document.getElementById('search-nmatches');
            const searchResults = document.getElementById('search-results');
            const searchForm = document.getElementById('search-form');
            const searchBox = document.getElementById('search-text');
            const positionOverflow = 20;
            const documents = #{search_json};
            const idx = lunr(function() {
              this.ref('id');
              this.field('title');
              this.field('text');
              this.metadataWhitelist = ['position'];

              documents.forEach(doc => {
                this.add(doc)
              });
            });
            function processSearchText(searchText) {
              const results = idx.search(searchText).map(match => {
                const doc = documents.find(d => d.id == match.ref);
                const result = document.createElement('li');
                result.classList.add('list-group-item');
                const link = document.createElement('a');
                const br = document.createElement('br');
                link.setAttribute('href', match.ref);
                link.innerHTML = doc.title;
                result.append(link, br);
                const metadata = match.matchData.metadata;
                for(const term in metadata) {
                  const datum = metadata[term];
                  for(const type in datum) {
                    datum[type].position.forEach(pos => {
                      const start = pos[0];
                      const end = pos[0] + pos[1];
                      const text = doc[type];
                      const textMatch = text.substring(start, end)
                      const matchingText = document.createElement('mark');
                      const overflowLeft = document.createElement('span');
                      overflowLeft.classList.add('overflow-text-left');
                      const overflowRight = document.createElement('span');
                      overflowRight.classList.add('overflow-text-right');
                      const reLeft = /.{#{SEARCH_RESULT_OVERFLOW}}$/s;
                      let left = text.substring(0, start - 1).search(reLeft) + 1;
                      while(text[left] && text[left].trim() == text[left]) {
                        left--;
                      }
                      const reRight = /^.{#{SEARCH_RESULT_OVERFLOW}}/s;
                      let right = text.length;
                      if(rightMatch = text.substring(end + 1).match(reRight)) {
                        right = rightMatch[0].length + end;
                        while(text[right] && text[right].trim() == text[right]) {
                          right++;
                        }
                      }
                      overflowLeft.textContent = text.substring(left, start - 1);
                      matchingText.textContent = textMatch;
                      overflowRight.textContent = text.substring(end + 1, right);
                      result.append(overflowLeft, matchingText, overflowRight);
                    });
                  }
                }
                return result;
              });
              searchResults.replaceChildren(...results);
              const n = results.length;
              nmatches.textContent = n == 1 ? (n + ' match') : (n + ' matches');
              resultsContainer.classList.remove('hidden');
            }
            searchForm.addEventListener('submit', e => {
              e.preventDefault();
              const searchText = searchBox.value;
              processSearchText(searchText);
            });
          })();
        JS
      end
    end
  end
end
