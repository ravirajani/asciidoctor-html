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
            <div id="search-form-spinner" class="d-flex justify-content-center">
              <div class="spinner-border" role="status">
                <span class="visually-hidden">Loading...</span>
              </div>
            </div>
            <form id="search-form" class="search-form hidden">
              <input type="text" id="search-text" name="search-text" class="form-control search-box" placeholder="Search">
              <button type="submit" class="btn btn-primary search-btn">Go</button>
            </form>
          </div>
          <div id="search-results-container" class="hidden">
          <h5 class="search-matches-title">Found <span id="search-nmatches">0 matches</span></h5>
          <ul id="search-results" class="search-results list-group list-group-flush"></ul>
          </div>
        HTML
        Template.html(
          content,
          nav_items,
          title: @title,
          short_title: @short_title,
          authors: display_authors,
          date: @date,
          chapsubheading: "Search",
          langs: [],
          at_head_end: %(<script defer src="https://cdn.jsdelivr.net/npm/lunr@2.3.9/lunr.min.js"></script>),
          at_body_end: %(<script type="module">#{lunr_script}</script>)
        )
      end

      def build_index(key, html)
        filename = "#{key}.html"
        doctree = Nokogiri::HTML5.parse html, max_errors: 10
        puts("! #{filename}") unless doctree.errors.empty?
        doctree.errors.each do |err|
          puts err
        end
        ref = @refs[key]
        page_text = []
        index = [{
          id: filename,
          title: ref["chapref"]
        }]
        doctree.css(".title-prefix").each { |el| el.content += ": " }
        doctree.css(".title-suffix").each { |el| el.content = " (#{el.content})" }
        doctree.at_css("#content-container").elements.each do |el|
          if el.name == "section" && (sectid = el.attribute "id")
            index << {
              id: "#{filename}##{sectid}",
              title: "#{ref["chapref"]} › #{ref[sectid.to_s]}",
              text: el.text
            }
          else
            page_text << el.text
          end
        end
        index.first[:text] = page_text.join(" ")
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
            const normalisePossessive = function (builder) {
              // Define a pipeline function that removes apostrophe
              const pipelineFunction = function (token) {
                if(token.toString().endsWith('’s')) {
                  return token.update(() => token.toString().slice(0,-2));
                } else {
                  return token;
                }
              }
              // Register the pipeline function so the index can be serialised
              lunr.Pipeline.registerFunction(pipelineFunction, 'normalisePossessive');
              // Add the pipeline function to both the indexing pipeline and the
              // searching pipeline
              builder.pipeline.before(lunr.stemmer, pipelineFunction);
              builder.searchPipeline.before(lunr.stemmer, pipelineFunction);
            }
            const resultsContainer = document.getElementById('search-results-container');
            const nmatches = document.getElementById('search-nmatches');
            const searchResults = document.getElementById('search-results');
            const searchForm = document.getElementById('search-form');
            const searchBox = document.getElementById('search-text');
            const positionOverflow = 20;
            const documents = #{search_json};
            const idx = lunr(function() {
              this.use(normalisePossessive);
              this.ref('id');
              this.field('text');
              this.metadataWhitelist = ['position'];

              documents.forEach(doc => {
                this.add(doc);
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
                      const textMatch = text.substring(start, end);
                      const matchingText = document.createElement('mark');
                      const overflowLeft = document.createElement('span');
                      overflowLeft.classList.add('overflow-text-left');
                      const overflowRight = document.createElement('span');
                      overflowRight.classList.add('overflow-text-right');
                      let left = start - #{SEARCH_RESULT_OVERFLOW};
                      while(text[left] && text[left].trim() == text[left]) {
                        left--;
                      }
                      let right = end + #{SEARCH_RESULT_OVERFLOW};
                      while(text[right] && text[right].trim() == text[right]) {
                        right++;
                      }
                      let overflowRightText = text.substring(end, right);
                      if(overflowRightText.length > 0 && text[right - 1] != '.') {
                        overflowRightText += '… ';
                      } else {
                        overflowRightText += ' ';
                      }
                      overflowLeft.textContent = text.substring(left + 1, start);
                      matchingText.textContent = textMatch;
                      overflowRight.textContent = overflowRightText;
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
            document.getElementById('search-form-spinner').classList.add('hidden');
            searchForm.classList.remove('hidden');
            searchForm.addEventListener('submit', e => {
              e.preventDefault();
              const searchText = searchBox.value;
              processSearchText(searchText);
            });
            searchBox.focus();
          })();
        JS
      end
    end
  end
end
