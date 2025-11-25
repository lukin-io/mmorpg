# frozen_string_literal: true

module Social
  class CommunityAnnouncementJob < ApplicationJob
    queue_as :social

    def perform(event:, payload:)
      Social::WebhookDispatcher.new(event:, payload:).post!
    end
  end
end
