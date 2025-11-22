# frozen_string_literal: true

module Game
  module Moderation
    # NpcIntake validates NPC magistrate/guard state and opens moderation tickets.
    #
    # Usage:
    #   Game::Moderation::NpcIntake.new.call(reporter: user, npc_key: "magistrate_serra", ...)
    class NpcIntake
      class InvalidNpc < StandardError; end

      def initialize(population_directory: Game::World::PopulationDirectory.instance, audit_logger: AuditLogger)
        @population_directory = population_directory
        @audit_logger = audit_logger
      end

      def call(reporter:, npc_key:, category:, description:, evidence: {}, character: nil)
        npc = population_directory.npc(npc_key)
        raise InvalidNpc, "NPC cannot accept reports" unless npc&.offers_reports?

        report = NpcReport.create!(
          reporter: reporter,
          character: character,
          npc_key: npc_key,
          category:,
          description:,
          evidence: evidence,
          metadata: {
            region: npc.region,
            location: npc.location,
            roles: npc.roles
          }
        )

        audit_logger.log(
          actor: reporter,
          action: "npc_report.submitted",
          target: report,
          metadata: {category:, npc_key:}
        )

        report
      end

      private

      attr_reader :population_directory, :audit_logger
    end
  end
end
