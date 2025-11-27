# frozen_string_literal: true

module Auth
  class DeviceIdentifier
    COOKIE_KEY = :elselands_device_id
    SESSION_KEY = :elselands_device_id

    def self.resolve(request)
      new(request).resolve
    end

    def initialize(request)
      @request = request
    end

    def resolve
      identifier = cookie_device_id || session_device_id || generate_identifier
      persist(identifier)
      identifier
    end

    private

    attr_reader :request

    def cookie_device_id
      cookie_jar&.encrypted&.[](COOKIE_KEY)
    rescue NoMethodError
      nil
    end

    def session_device_id
      session&.[](SESSION_KEY)
    end

    def generate_identifier
      SecureRandom.uuid
    end

    def persist(identifier)
      session[SESSION_KEY] = identifier if session
      cookie_jar&.encrypted&.[]=(COOKIE_KEY, {
        value: identifier,
        expires: 1.year.from_now
      })
    rescue NoMethodError
      session[SESSION_KEY] = identifier if session
    end

    def cookie_jar
      request.cookie_jar if request.respond_to?(:cookie_jar)
    end

    def session
      request.session if request.respond_to?(:session)
    end
  end
end
