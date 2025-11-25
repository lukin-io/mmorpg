# frozen_string_literal: true

module Arena
  class RewardJob < ApplicationJob
    queue_as :arena

    def perform(match_id)
      match = ArenaMatch.find_by(id: match_id)
      return unless match&.completed?

      match.arena_participations.each do |participation|
        next unless participation.result == "victory"

        MailMessages::SystemNotifier.new.deliver!(
          recipients: [participation.user],
          subject: "Arena Victory Rewards",
          body: "Congratulations! You placed #{participation.result.upcase} in match ##{match.id}.",
          attachment_payload: participation.reward_payload.presence || {},
          origin_metadata: {
            arena_match_id: match.id,
            arena_season_id: match.arena_season_id
          }
        )
      end
    end
  end
end
