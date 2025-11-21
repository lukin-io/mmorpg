# frozen_string_literal: true

module Guilds
  # Encapsulates guild role permissions so controllers/services can remain lean.
  #
  # Usage:
  #   Guilds::PermissionMatrix.new(role: membership.role).allows?(:invite_members)
  #
  # Returns:
  #   Boolean flag for a given capability.
  class PermissionMatrix
    CAPABILITIES = {
      invite_members: %i[recruiter officer leader],
      manage_bank: %i[quartermaster officer leader],
      start_war: %i[warlord leader],
      review_applications: %i[recruiter officer leader],
      promote_members: %i[officer leader]
    }.freeze

    def initialize(role:)
      @role = role&.to_sym
    end

    def allows?(capability)
      CAPABILITIES.fetch(capability, []).include?(role)
    end

    private

    attr_reader :role
  end
end

