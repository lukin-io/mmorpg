# frozen_string_literal: true

module Clans
  # ApplicationPipeline encapsulates the recruitment workflow:
  # - capture vetting answers/referrals
  # - auto-accept based on clan-configured rules
  # - approve/reject decisions and membership creation
  #
  # Usage:
  #   service = Clans::ApplicationPipeline.new(clan: clan, actor: current_user)
  #   service.submit!(answers: params[:answers], character: current_character, referral: User.find_by(id: params[:referral_id]))
  #   service.review!(application:, decision: :approved, reviewer: current_user)
  class ApplicationPipeline
    def initialize(clan:, actor:, logger: Clans::LogWriter.new(clan:))
      @clan = clan
      @actor = actor
      @logger = logger
    end

    def submit!(answers:, character:, referral: nil)
      application = clan.clan_applications.create!(
        applicant: actor,
        character: character,
        referral_user: referral,
        vetting_answers: answers,
        status: :pending
      )

      if auto_accept?(application)
        finalize_application!(application:, reviewer: nil, status: :auto_accepted, reason: "Auto-accepted via recruitment rules.")
      end

      application
    end

    def review!(application:, reviewer:, decision:, reason: nil)
      case decision.to_sym
      when :approved
        finalize_application!(application:, reviewer:, status: :approved, reason:)
      when :rejected
        application.update!(
          status: :rejected,
          reviewed_by: reviewer,
          reviewed_at: Time.current,
          decision_reason: reason
        )
        logger.record!(action: "applications.rejected", actor: reviewer, metadata: {application_id: application.id, reason: reason})
      else
        raise ArgumentError, "Unknown decision #{decision}"
      end
    end

    private

    attr_reader :clan, :actor, :logger

    def auto_accept?(application)
      rules = clan.recruitment_settings.fetch("auto_accept", {})
      min_level = rules.fetch("min_level", 0).to_i
      requires_referral = rules.fetch("requires_referral", false)
      level_ok = application.character.present? && application.character.level >= min_level
      referral_ok = !requires_referral || application.referral_user_id.present?

      level_ok && referral_ok
    end

    def finalize_application!(application:, reviewer:, status:, reason:)
      membership = clan.clan_memberships.find_or_create_by!(user: application.applicant) do |record|
        record.role = :member
        record.joined_at = Time.current
      end

      application.update!(
        status: status,
        auto_accepted: status == :auto_accepted,
        reviewed_by: reviewer,
        reviewed_at: Time.current,
        decision_reason: reason
      )

      logger.record!(
        action: "applications.#{status}",
        actor: reviewer,
        metadata: {
          application_id: application.id,
          membership_id: membership.id,
          reason: reason
        }
      )
    end
  end
end
