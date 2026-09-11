# frozen_string_literal: true

require "rails_helper"

RSpec.describe "shared/_flash", type: :view do
  def notification
    Nokogiri::HTML.fragment(rendered).at_css(".nl-flash")
  end

  %w[notice success].each do |type|
    it "renders a temporary, dismissible #{type} with a bounded lifetime" do
      render partial: "shared/flash", locals: {type:, message: "Operation completed."}

      expect(notification["data-controller"]).to eq("flash")
      expect(notification["data-flash-timeout-value"]).to eq("5000")
      expect(notification.attribute("data-turbo-temporary")).to be_present
      expect(notification["role"]).to eq("status")
      expect(notification["class"]).to include("nl-flash--notice")
      expect(notification.at_css("button[aria-label='Dismiss notification']")["type"]).to eq("button")
      expect(notification.text).to include("Operation completed.")
    end
  end

  %w[alert error].each do |type|
    it "keeps a #{type} readable until it is dismissed or navigation replaces it" do
      render partial: "shared/flash", locals: {type:, message: "The action could not be completed."}

      expect(notification["data-flash-timeout-value"]).to eq("0")
      expect(notification["role"]).to eq("alert")
      expect(notification.attribute("data-turbo-temporary")).to be_present
      expect(notification.at_css("button[aria-label='Dismiss notification']")).to be_present
    end
  end

  it "supports a notice local through the same presentation" do
    render partial: "shared/flash", locals: {notice: "Stats saved"}

    expect(notification["class"]).to include("nl-flash--notice")
    expect(notification["data-controller"]).to eq("flash")
    expect(notification.text).to include("Stats saved")
  end

  it "supports an alert local through the same presentation" do
    render partial: "shared/flash", locals: {alert: "Not enough NV"}

    expect(notification["class"]).to include("nl-flash--alert")
    expect(notification["data-flash-timeout-value"]).to eq("0")
    expect(notification.text).to include("Not enough NV")
  end

  it "escapes message content instead of executing markup" do
    message = '<script>alert("unsafe")</script><b>Untrusted message</b>'

    render partial: "shared/flash", locals: {type: :alert, message:}

    expect(notification.css("script, b")).to be_empty
    expect(notification.text).to include(message)
  end

  it "does not create an empty notification" do
    render partial: "shared/flash", locals: {type: :notice, message: ""}

    expect(notification).to be_nil
  end

  {timedout: true, world_action_result_offer_id: 123}.each do |type, message|
    it "does not render the internal #{type} flash value as player-facing text" do
      render partial: "shared/flash", locals: {type:, message:}

      expect(notification).to be_nil
    end
  end
end
