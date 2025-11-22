# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :require_moderator!

    private

    def require_moderator!
      raise Pundit::NotAuthorizedError unless current_user&.moderator?
    end
  end
end
