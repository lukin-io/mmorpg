# frozen_string_literal: true

module Game
  module Moderation
    # NpcIntake validates NPC magistrate/guard state and opens moderation tickets.
    #
    # Usage:
    #   Game::Moderation::NpcIntake.new.call(reporter: user, npc_key: "magistrate_serra", ...)
    class NpcIntake
      class InvalidNpc < StandardError; end

      def initialize(population_directory: Game::World::PopulationDirectory.instance, audit_logger: AuditLogger, report_intake: ::Moderation::ReportIntake.new)
        @population_directory = population_directory
        @audit_logger = audit_logger
        @report_intake = report_intake
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

        intake_ticket = report_intake.call(
          reporter:,
          subject_user: character&.user,
          subject_character: character,
          source: :npc,
          category:,
          description:,
          evidence:,
          metadata: report.metadata.merge(npc_key: npc_key),
          npc_report: report
        )

        report.update!(moderation_ticket: intake_ticket)
        report
      end

      private

      attr_reader :population_directory, :audit_logger, :report_intake
    end
  end
end
