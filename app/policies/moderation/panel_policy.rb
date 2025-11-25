# frozen_string_literal: true

module Moderation
  class PanelPolicy < Struct.new(:user, :panel)
    def show?
      user.present?
    end
  end
end
