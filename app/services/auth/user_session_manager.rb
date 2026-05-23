# frozen_string_literal: true

module Auth
  class UserSessionManager
    def self.login!(user:, request:)
      new(user: user, request: request).login!
    end

    def self.logout!(user:, request:)
      new(user: user, request: request).logout!
    end

    def initialize(user:, request:)
      @user = user
      @request = request
      @device_id = Auth::DeviceIdentifier.resolve(request)
    end

    def login!
      session = user.user_sessions.find_or_initialize_by(device_id: device_id)
      now = Time.current

      session.assign_attributes(
        signed_in_at: session.signed_in_at || now,
        last_seen_at: now,
        signed_out_at: nil
      )

      session.save!
      user.update!(last_seen_at: now)

      session
    end

    def logout!
      session = user.user_sessions.find_by(device_id: device_id)
      return unless session

      session.close!(timestamp: Time.current)
    end

    attr_reader :device_id

    private

    attr_reader :user, :request
  end
end
