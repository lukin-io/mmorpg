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

      merged_metadata = (session.metadata || {}).merge(platform: request.params[:platform]).compact

      session.assign_attributes(
        user_agent: request.user_agent.to_s.first(255),
        ip_address: request.ip,
        signed_in_at: session.signed_in_at || now,
        last_seen_at: now,
        status: UserSession::STATUS_VALUES[:online],
        metadata: merged_metadata
      )

      session.save!
      user.update!(
        last_seen_at: now,
        session_metadata: merged_metadata.merge(device_id: session.device_id, ip: request.ip)
      )

      Presence::Publisher.new.online!(user: user, session: session)
      session
    end

    def logout!
      session = user.user_sessions.find_by(device_id: device_id)
      return unless session

      session.mark_offline!(timestamp: Time.current)
      Presence::Publisher.new.offline!(user: user, session: session)
    end

    attr_reader :device_id

    private

    attr_reader :user, :request
  end
end
