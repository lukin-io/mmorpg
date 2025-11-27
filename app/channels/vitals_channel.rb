# frozen_string_literal: true

# Real-time HP/MP updates for a character
# Only allows subscribing to own character
#
# @example Subscribe to vitals
#   consumer.subscriptions.create({ channel: "VitalsChannel", character_id: 123 })
#
class VitalsChannel < ApplicationCable::Channel
  def subscribed
    @character = Character.find_by(id: params[:character_id])

    # Only allow subscribing to own character
    if @character && @character.user_id == current_user.id
      stream_from "character:#{@character.id}:vitals"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Request current vitals state
  def request_state
    return unless @character

    service = Characters::VitalsService.new(@character)

    transmit({
      type: "vitals_state",
      current_hp: @character.current_hp,
      max_hp: @character.max_hp,
      current_mp: @character.current_mp,
      max_mp: @character.max_mp,
      hp_percent: service.hp_percent,
      mp_percent: service.mp_percent,
      hp_regen_interval: @character.hp_regen_interval,
      mp_regen_interval: @character.mp_regen_interval,
      in_combat: @character.in_combat,
      needs_regen: service.needs_regen?
    })
  end
end
