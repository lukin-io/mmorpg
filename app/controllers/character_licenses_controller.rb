# frozen_string_literal: true

# Shows the current character's purchased licenses at the current server time.
# Read-only browsing does not activate, extend, or consume a permission.
class CharacterLicensesController < ApplicationController
  before_action :ensure_active_character!

  def index
    @character = current_character
    authorize @character, :manage_progression?
    @licenses = @character.character_licenses.active_at(Time.current).order(expires_at: :asc, id: :asc).limit(100).to_a
    @equipment = @character.inventory.inventory_items.equipped.includes(:item_template).index_by(&:equipment_slot)
    expires_now
  end
end
