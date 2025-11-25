# frozen_string_literal: true

module Clans
  # PermissionMatrix evaluates a clan member's capabilities based on per-clan
  # overrides stored in ClanRolePermission plus the baseline defaults defined in
  # config/gameplay/clans.yml.
  #
  # Usage:
  #   matrix = Clans::PermissionMatrix.new(clan:, membership: membership)
  #   matrix.allows?(:manage_treasury)
  class PermissionMatrix
    class << self
      def seed_defaults!(clan:)
        keys = Array(config.dig("permissions", "keys"))
        defaults = config.dig("permissions", "defaults") || {}

        ClanMembership.roles.each_key do |role|
          keys.each do |permission|
            default_enabled = defaults.dig(role.to_s, permission.to_s) ? true : false
            clan.clan_role_permissions.find_or_create_by!(role:, permission_key: permission) do |record|
              record.enabled = default_enabled
            end
          end
        end
      end

      def config
        Rails.configuration.x.clans
      end
    end

    def initialize(clan:, membership:)
      @clan = clan
      @membership = membership
    end

    def allows?(permission_key)
      return false unless membership

      record = cached_permissions[permission_key.to_s]
      return record if record.in?([true, false])

      default_permission(permission_key)
    end

    private

    attr_reader :clan, :membership

    def cached_permissions
      @cached_permissions ||= clan.clan_role_permissions.where(role: membership.role).each_with_object({}) do |permission, memo|
        memo[permission.permission_key.to_s] = permission.enabled?
      end
    end

    def default_permission(permission_key)
      defaults = self.class.config.dig("permissions", "defaults") || {}
      defaults.dig(membership.role.to_s, permission_key.to_s) ? true : false
    end
  end
end
