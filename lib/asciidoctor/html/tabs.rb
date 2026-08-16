# frozen_string_literal: true

require_relative "utils"

module Asciidoctor
  module Html
    # Helpers for the tabs conversion
    module Tabs
      def self.convert_tabs(node)
        tabs_id = node.attr "tabs-id"
        nav = [%(<div class="nav nav-tabs" role="tablist">)]
        panes = [%(<div class="tab-content">)]
        pane_number = 1
        node.items.each do |terms, dd|
          return %(<div class="text-danger">Definition is required.</div>) unless dd

          active = pane_number == 1
          tab_id = "tab-#{tabs_id}-#{pane_number}"
          pane_id = "#{tab_id}-pane"
          terms.each do |dt|
            class_attr = %( class="nav-link#{" active" if active}")
            target_attr = %( data-bs-target="##{pane_id}")
            selected_attr = %( aria-selected="#{active ? "true" : "false"}")
            other_attrs = %( data-bs-toggle="tab" type="button" role="tab" aria-controls="#{pane_id}")
            id_attr = %( id="#{tab_id}")
            nav << %(<button#{id_attr}#{class_attr}#{target_attr}#{other_attrs}#{selected_attr}>#{dt.text}</button>)
          end

          class_attr = %( class="tab-pane#{" show active" if active}")
          id_attr = %( id="#{pane_id}")
          other_attrs = %( role="tabpanel" aria-labelledby="#{tab_id}" tabindex="0")
          panes << %(<div#{id_attr}#{class_attr}#{other_attrs}>)
          panes << %(<p>#{dd.text}</p>) if dd.text?
          panes << dd.content if dd.blocks?
          panes << "</div>"
          pane_number += 1
        end
        nav << "</div> <!-- .nav.nav-tabs -->\n"
        panes << "</div> <!-- .tab-content -->\n"
        content = %(<div class="tabs">\n#{nav.join("\n")}#{panes.join("\n")}</div> <!-- .tabs -->\n)
        Utils.wrap_id_classes_with_title(content, node, node.id, "tabs-wrapper")
      end
    end
  end
end
