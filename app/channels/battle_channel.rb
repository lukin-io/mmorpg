# frozen_string_literal: true

# Real-time combat updates for a battle
# Used by turn_combat_controller.js for combat UI updates
#
# @example Subscribe to battle updates
#   consumer.subscriptions.create({ channel: "BattleChannel", battle_id: 123 })
#
class BattleChannel < ApplicationCable::Channel
  def subscribed
    @battle = Battle.find_by(id: params[:battle_id])

    # Only allow subscribing to battles the user's character is participating in
    if @battle && user_in_battle?
      stream_from "battle:#{@battle.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  # Request current battle state
  def request_state
    return unless @battle

    transmit({
      type: "battle_state",
      battle_id: @battle.id,
      status: @battle.status,
      turn_number: @battle.turn_number,
      participants: @battle.battle_participants.map do |p|
        {
          id: p.id,
          name: p.combatant_name,
          team: p.team,
          current_hp: p.current_hp,
          max_hp: p.max_hp,
          current_mp: p.current_mp,
          max_mp: p.max_mp,
          is_alive: p.is_alive
        }
      end
    })
  end

  private

  def user_in_battle?
    return false unless current_user

    @battle.battle_participants
      .joins(:character)
      .exists?(characters: {user_id: current_user.id})
  end
end
