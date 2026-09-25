# frozen_string_literal: true

module Game
  module Clans
    # Formula-facing aggregate of fortress building bonuses for a character.
    class FortressBuffs
      def initialize(character:)
        @character = character
      end

      def totals
        @totals ||= begin
          membership = character.clan_membership
          return {} unless membership

          FortressBuilding.bonus_totals_for_clan(membership.clan)
        end
      end

      def attack_bonus = totals["attack"].to_i
      def defense_bonus = totals["defense"].to_i
      def hp_bonus = totals["hp"].to_i
      def accuracy_bonus = totals["accuracy"].to_i
      def evasion_bonus = totals["evasion"].to_i
      def luck_bonus = totals["luck"].to_i
      def travel_reduction_seconds = totals["travel_reduction_seconds"].to_i
      def nv_find_bonus_percent = totals["nv_find_bonus_percent"].to_i

      private

      attr_reader :character
    end
  end
end
