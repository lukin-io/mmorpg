# frozen_string_literal: true

# Authorizes access to the management namespace as one privileged surface.
class ManagePolicy < ApplicationPolicy
  def access?
    user&.has_role?(:admin) || false
  end
end
