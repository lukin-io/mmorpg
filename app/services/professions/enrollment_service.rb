# frozen_string_literal: true

module Professions
  # Enrolls a character into a profession respecting slot limits.
  #
  # Usage:
  #   Professions::EnrollmentService.new(character:, profession:).enroll!
  class EnrollmentService
    def initialize(character:, profession:)
      @character = character
      @profession = profession
    end

    def enroll!
      progress = character.profession_progresses.create!(
        profession: profession,
        user: character.user,
        slot_kind: profession.slot_kind,
        skill_level: 1,
        mastery_tier: 0,
        experience: 0
      )
      equip_default_tool!(progress)
      progress
    end

    private

    attr_reader :character, :profession

    def equip_default_tool!(progress)
      tool = character.profession_tools.find_or_create_by!(profession:, tool_type: "#{profession.name} Kit") do |record|
        record.quality_rating = 10
        record.durability = 100
        record.max_durability = 100
        record.metadata = {"repair_materials" => {"Iron Ingot" => 1}}
      end
      progress.update!(equipped_tool: tool)
    end
  end
end
