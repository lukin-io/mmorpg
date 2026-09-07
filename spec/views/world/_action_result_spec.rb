# frozen_string_literal: true

require "rails_helper"

RSpec.describe "world/_action_result.html.erb", type: :view do
  it "renders an escaped, named result dialog with both dismissal controls" do
    render partial: "world/action_result", locals: {message: "No plants <script>alert('x')</script>"}

    expect(rendered).to have_css("dialog[aria-label='Search result'][aria-describedby='world-action-result-message']", visible: :all)
    expect(rendered).to have_css("[data-controller='world-result'][data-action='keydown.esc->world-result#close']")
    expect(rendered).to have_css("button[aria-label='Close search result'][data-action='world-result#close']", visible: :all)
    expect(rendered).to have_button("Close", exact: true, visible: :all)
    expect(rendered).to include("&lt;script&gt;")
    expect(rendered).not_to have_css("script", visible: :all)
  end
end
