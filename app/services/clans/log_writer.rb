# frozen_string_literal: true

module Clans
  # LogWriter is a thin helper around ClanLogEntry so services/controllers can
  # emit consistent audit rows for territory changes, treasury movements, etc.
  #
  # Usage:
  #   Clans::LogWriter.new(clan: clan).record!(action: "war.declare", actor: user, metadata: {...})
  class LogWriter
    def initialize(clan:)
      @clan = clan
    end

    def record!(action:, actor: nil, metadata: {})
      clan.clan_log_entries.create!(
        action: action,
        actor: actor,
        metadata: metadata
      )
    end

    private

    attr_reader :clan
  end
end
