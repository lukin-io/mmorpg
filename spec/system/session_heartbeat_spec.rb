# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Session heartbeat", type: :system, js: true do
  let(:user) { create(:user) }
  let(:character) { create(:character, user:) }
  let(:zone) { create(:zone, :mvp_outdoor_region) }
  let!(:position) { create(:character_position, character:, zone:, x: 4, y: 6) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before { login_as(user, scope: :user) }

  it "sends the shell CSRF token through Beacon and fetch fallback without creating another session" do
    visit chat_channel_path(create(:chat_channel, :global))
    expect(page).to have_css('meta[name="csrf-token"]', visible: :all)
    session = user.user_sessions.sole
    page.execute_script(<<~JS, session_ping_path)
      window.heartbeatController = window.Stimulus.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller="online-reload"]'), "online-reload"
      )
      clearInterval(window.heartbeatController.ticker)
      const pingPath = arguments[0]
      window.initialHeartbeatObserver = new PerformanceObserver(list => {
        for (const entry of list.getEntries()) {
          if (entry.initiatorType === "beacon" && new URL(entry.name).pathname === pingPath) {
            document.body.dataset.initialHeartbeatStatus = entry.responseStatus
            window.initialHeartbeatObserver.disconnect()
          }
        }
      })
      window.initialHeartbeatObserver.observe({ type: "resource", buffered: true })
    JS
    expect(page).to have_css('body[data-initial-heartbeat-status="204"]')

    session.update!(last_seen_at: 10.minutes.ago)
    previous_seen_at = session.last_seen_at
    expect(page.evaluate_async_script(<<~JS, session_ping_path)).to eq(422)
      const done = arguments[arguments.length - 1]
      fetch(arguments[0], { method: "POST", credentials: "same-origin" })
        .then(response => done(response.status))
    JS
    expect(session.reload.last_seen_at).to eq(previous_seen_at)

    page.execute_script(<<~JS, session_ping_path)
      window.heartbeatPath = arguments[0]
      window.heartbeatNativeBeacon = navigator.sendBeacon.bind(navigator)
      window.heartbeatNativeFetch = window.fetch.bind(window)
      window.heartbeatTokenMatches = body => body instanceof FormData &&
        body.get("authenticity_token") === document.querySelector('meta[name="csrf-token"]').content
      window.heartbeatStartedAt = performance.now()
      window.heartbeatObserver = new PerformanceObserver(list => {
        for (const entry of list.getEntries()) {
          if (entry.initiatorType === "beacon" && entry.startTime >= window.heartbeatStartedAt &&
              new URL(entry.name).pathname === window.heartbeatPath) {
            document.body.dataset.heartbeatBeaconStatus = entry.responseStatus
          }
        }
      })
      window.heartbeatObserver.observe({ type: "resource" })
      navigator.sendBeacon = (url, body) => {
        document.body.dataset.heartbeatBeaconToken = window.heartbeatTokenMatches(body)
        return window.heartbeatNativeBeacon(url, body)
      }
      window.heartbeatController.pingServer()
    JS
    expect(page).to have_css('body[data-heartbeat-beacon-token="true"][data-heartbeat-beacon-status="204"]')
    expect(session.reload.last_seen_at).to be > previous_seen_at
    expect(session.signed_out_at).to be_nil

    session.update!(last_seen_at: 10.minutes.ago)
    previous_seen_at = session.last_seen_at
    page.execute_script(<<~JS)
      navigator.sendBeacon = () => false
      window.fetch = async (url, options) => {
        const response = await window.heartbeatNativeFetch(url, options)
        if (url === window.heartbeatPath) {
          document.body.dataset.heartbeatFetchToken = window.heartbeatTokenMatches(options.body)
          document.body.dataset.heartbeatFetchCredentials = options.credentials
          document.body.dataset.heartbeatFetchStatus = response.status
        }
        return response
      }
      window.heartbeatController.pingServer()
    JS
    expect(page).to have_css('body[data-heartbeat-fetch-token="true"][data-heartbeat-fetch-credentials="same-origin"][data-heartbeat-fetch-status="204"]')
    expect(session.reload.last_seen_at).to be > previous_seen_at
    expect(user.user_sessions.pluck(:id)).to eq([session.id])
    expect(session.signed_out_at).to be_nil
  end
end
