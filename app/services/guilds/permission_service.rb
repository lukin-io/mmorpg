# frozen_string_literal: true

module Guilds
  # PermissionService centralizes guild rank permission checks (bank, invites, etc.).
  # Usage:
  #   Guilds::PermissionService.new(membership: membership).ensure!(:manage_bank)
  # Returns:
  #   true when allowed. Raises Pundit::NotAuthorizedError otherwise.
  class PermissionService
    def initialize(membership:)
      @membership = membership
    end

    def allowed?(permission)
      return false unless membership&.guild_rank

      membership.guild_rank_allows?(permission)
    end

    def ensure!(permission)
      return true if allowed?(permission)

      raise Pundit::NotAuthorizedError, "Guild permission #{permission} required"
    end

    private

    attr_reader :membership
  end
end
