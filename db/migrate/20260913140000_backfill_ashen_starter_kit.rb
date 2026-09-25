# frozen_string_literal: true

# Backfills the Ashen starter kit (bait + NV + blade) for characters created before
# Game::World::StarterKit was hooked into playable-character bootstrap.
class BackfillAshenStarterKit < ActiveRecord::Migration[8.1]
  def up
    return unless defined?(Character) && defined?(Game::World::StarterKit)

    Game::World::StarterKit.ensure_weapon_template! if Game::World::StarterKit.respond_to?(:ensure_weapon_template!)

    updated = 0
    Character.find_each do |character|
      Game::World::StarterKit.new(character:).call
      updated += 1 if character.reload.metadata.to_h[Game::World::StarterKit::METADATA_KEY].present?
    end
    say "ensured ashen starter kit for #{updated} characters"
  end

  def down
  end
end
