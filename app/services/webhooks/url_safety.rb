# frozen_string_literal: true

require "ipaddr"

module Webhooks
  class UnsafeUrlError < StandardError; end

  module UrlSafety
    ALLOWED_SCHEMES = %w[http https].freeze

    module_function

    def ensure_safe!(uri)
      raise Webhooks::UnsafeUrlError, "Unsafe webhook URL" unless safe?(uri)
    end

    def safe?(uri)
      return false if uri.blank? || uri.host.blank?
      return false unless ALLOWED_SCHEMES.include?(uri.scheme)
      return false if localhost?(uri.host)
      return false if private_ip?(uri.host)

      true
    end

    def localhost?(host)
      host.casecmp("localhost").zero?
    end

    def private_ip?(host)
      ip = IPAddr.new(host)
      ip.loopback? || ip.private?
    rescue IPAddr::InvalidAddressError
      false
    end
  end
end
