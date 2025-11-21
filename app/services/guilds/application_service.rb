# frozen_string_literal: true

module Guilds
  # Handles the lifecycle of guild applications (submit, approve, reject) with auditing hooks.
  #
  # Usage:
  #   Guilds::ApplicationService.new(guild: guild, applicant: user).submit!(answers: {...})
  #   Guilds::ApplicationService.new(guild: guild, applicant: applicant).approve!(reviewer: current_user)
  #
  # Raises:
  #   ActiveRecord::RecordInvalid when validations fail.
  class ApplicationService
    def initialize(guild:, applicant:)
      @guild = guild
      @applicant = applicant
    end

    def submit!(answers:)
      guild.guild_applications.create!(
        applicant:,
        answers:,
        status: :pending
      )
    end

    def approve!(reviewer:)
      application = find_application!
      application.approve!(reviewer:)
      guild.guild_memberships.create!(user: applicant, role: :member, status: :active, joined_at: Time.current)
      application
    end

    def reject!(reviewer:, reason: nil)
      application = find_application!
      application.reject!(reviewer:)
      application.update!(answers: application.answers.merge("rejection_reason" => reason).compact) if reason.present?
      application
    end

    private

    attr_reader :guild, :applicant

    def find_application!
      guild.guild_applications.find_by!(applicant:)
    end
  end
end

