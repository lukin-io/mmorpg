# frozen_string_literal: true

require "cgi"

class PublicProfilesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :ensure_device_identifier
  before_action :set_profile, only: :show

  def show
    respond_to do |format|
      format.html # renders show.html.erb
      format.json { render json: public_profile_payload }
    end
  end

  def pinfo
    @profile_name = CGI.unescape(request.query_string.to_s.split(/[&=]/).first.to_s)
    set_profile
    render :show
  end

  private

  def set_profile
    lookup = (@profile_name.presence || params[:profile_name]).to_s
    @character = find_character(lookup)
    @user = @character&.user || User.find_by!(profile_name: lookup)
    @character ||= @user.character
    @equipment = equipped_items_for(@character)
    @viewer_character = current_user&.character if user_signed_in?
  end

  def find_character(name)
    return nil if name.blank?

    Character
      .includes(:user, :character_class, :guild, :clan, {inventory: {inventory_items: :item_template}}, {position: :zone})
      .find_by("LOWER(characters.name) = ?", name.downcase)
  end

  def equipped_items_for(character)
    return {} unless character&.inventory

    character.inventory.inventory_items.equipped.includes(:item_template).index_by do |item|
      item.equipment_slot.to_s.presence || item.item_template&.slot.to_s
    end
  end

  def public_profile_payload
    payload = Users::PublicProfile.new(user: @user).as_json
    return payload unless @character

    payload.merge(
      character: {
        id: @character.id,
        name: @character.name,
        level: @character.level,
        current_hp: @character.current_hp,
        max_hp: @character.max_hp,
        current_mp: @character.current_mp,
        max_mp: @character.max_mp
      }
    )
  end
end
