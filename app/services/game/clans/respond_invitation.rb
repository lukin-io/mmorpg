# frozen_string_literal: true

module Game
  module Clans
    # Accept or decline a pending clan invitation.
    class RespondInvitation
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(character:, invitation_id:, accept:)
        @character = character
        @invitation_id = invitation_id
        @accept = accept
      end

      def call
        invitation = ClanInvitation.pending.for_character(character).find_by(id: invitation_id)
        return fail!(I18n.t("game.clans.invite_gone")) unless invitation
        return fail!(I18n.t("game.clans.already_member")) if character.clan_membership && accept

        character.with_lock do
          invitation.lock!
          invitation.reload
          return fail!(I18n.t("game.clans.invite_gone")) unless invitation.pending?

          if accept
            ClanMembership.create!(
              clan: invitation.clan,
              character:,
              role: "worker",
              joined_at: Time.current
            )
            invitation.update!(status: "accepted", responded_at: Time.current)
            Result.new(success: true, message: I18n.t("game.clans.joined", name: invitation.clan.name))
          else
            invitation.update!(status: "declined", responded_at: Time.current)
            Result.new(success: true, message: I18n.t("game.clans.invite_declined"))
          end
        end
      rescue ActiveRecord::RecordInvalid => error
        fail!(error.record.errors.full_messages.to_sentence)
      end

      private

      attr_reader :character, :invitation_id, :accept

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
