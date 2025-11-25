# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_integration_token!

      private

      attr_reader :integration_token

      def authenticate_integration_token!
        token_value = request.headers["X-Integration-Token"] || params[:token]
        @integration_token = IntegrationToken.find_by(token: token_value)
        head :unauthorized unless @integration_token
      end
    end
  end
end
