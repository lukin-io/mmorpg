# frozen_string_literal: true

# Handles all battle-related actions including turn submission and combat resolution.
#
# Supports:
# - PvE battles (vs NPCs)
# - PvP battles (vs Players)
# - Arena battles (matchmaking-based)
#
# All combat logic is delegated to Game::Combat::TurnResolver.
class BattlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_battle, only: %i[show submit_turn flee surrender]
  before_action :set_participant, only: %i[submit_turn flee surrender]
  before_action :authorize_battle, only: %i[show submit_turn flee surrender]

  # GET /battles/:id
  # Display the combat interface
  def show
    @player_participant = @battle.battle_participants.find_by(character: current_character)
    @opponent_participant = @battle.battle_participants
      .where.not(id: @player_participant&.id)
      .first

    @combat_config = load_combat_config

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # POST /battles/:id/submit_turn
  # Submit turn actions for resolution
  def submit_turn
    # Parse actions from form
    attacks = parse_attacks(params[:attacks])
    blocks = parse_blocks(params[:blocks])
    skills = parse_skills(params[:skills])
    ap_used = params[:ap_used].to_i

    # Validate actions
    validator = Game::Combat::ActionValidator.new(@participant, load_combat_config)
    validation = validator.validate(attacks: attacks, blocks: blocks, skills: skills)

    unless validation.valid?
      return respond_with_error(validation.errors.first)
    end

    # Submit turn for this participant
    @participant.submit_turn!(
      attacks: attacks,
      blocks: blocks,
      skills: skills,
      ap_used: ap_used
    )

    # Generate NPC actions if opponent is NPC
    generate_npc_actions_if_needed

    # Check if all participants are ready (simultaneous mode)
    if @battle.simultaneous? && @battle.all_participants_ready?
      resolve_round!
    else
      broadcast_ready_state
    end

    respond_to do |format|
      format.html { redirect_to battle_path(@battle) }
      format.turbo_stream { render :submit_turn }
    end
  end

  # POST /battles/:id/flee
  # Attempt to flee from combat
  def flee
    unless @participant.can_act?
      return respond_with_error("Cannot flee while unable to act")
    end

    # Flee chance based on agility
    flee_chance = calculate_flee_chance
    roll = rand(100)

    if roll < flee_chance
      # Successful flee
      end_battle_with_flee
      @fled = true
      @message = "You successfully fled from combat!"
    else
      # Failed flee - lose turn
      @participant.clear_turn!
      @fled = false
      @message = "Failed to flee! You lose your turn."

      # If opponent is NPC, resolve their turn
      generate_npc_actions_if_needed
      resolve_round! if @battle.all_participants_ready?
    end

    respond_to do |format|
      format.html { redirect_to @fled ? root_path : battle_path(@battle), notice: @message }
      format.turbo_stream
    end
  end

  # POST /battles/:id/surrender
  # Surrender the battle (instant loss)
  def surrender
    @participant.update!(is_alive: false, current_hp: 0)

    # Mark battle as completed
    winning_team = (@participant.team == "alpha") ? "beta" : "alpha"
    @battle.update!(status: :completed, winning_team: winning_team, ended_at: Time.current)

    # Broadcast battle end
    broadcast_battle_end(winning_team)

    respond_to do |format|
      format.html { redirect_to root_path, notice: "You have surrendered." }
      format.turbo_stream
    end
  end

  private

  def set_battle
    @battle = Battle.find(params[:id])
  end

  def set_participant
    @participant = @battle.battle_participants.find_by(character: current_character)
  end

  def authorize_battle
    unless @battle.battle_participants.exists?(character: current_character) ||
        @battle.battle_participants.joins(:character).exists?(characters: {user_id: current_user.id})
      redirect_to root_path, alert: "You are not part of this battle."
    end
  end

  def load_combat_config
    config_path = Rails.root.join("config/gameplay/combat_actions.yml")
    File.exist?(config_path) ? YAML.load_file(config_path) : {}
  end

  def parse_attacks(attacks_params)
    return [] if attacks_params.blank?

    attacks_params.to_unsafe_h.map do |body_part, action_key|
      next if action_key.blank?
      {body_part: body_part, action_key: action_key}
    end.compact
  end

  def parse_blocks(blocks_params)
    return [] if blocks_params.blank?

    blocks_params.to_unsafe_h.map do |body_part, action_key|
      next if action_key.blank?
      {body_part: body_part, action_key: action_key}
    end.compact
  end

  def parse_skills(skills_params)
    return [] if skills_params.blank?

    if skills_params.is_a?(String)
      JSON.parse(skills_params)
    else
      skills_params.to_a.map { |s| s.to_unsafe_h }
    end
  rescue
    []
  end

  def generate_npc_actions_if_needed
    npc_participants = @battle.battle_participants.where(participant_type: "npc").alive

    npc_participants.each do |npc_participant|
      next if npc_participant.turn_submitted?

      resolver = Game::Combat::TurnResolver.new(@battle, rng: Random.new(@battle.rng_seed || 12345))
      actions = resolver.generate_npc_actions(npc_participant)

      if actions
        npc_participant.submit_turn!(
          attacks: actions[:attacks],
          blocks: actions[:blocks],
          skills: actions[:skills],
          ap_used: 0
        )
      end
    end
  end

  def resolve_round!
    seed = @battle.rng_seed || SecureRandom.random_number(2**31)
    resolver = Game::Combat::TurnResolver.new(@battle, rng: Random.new(seed))
    @result = resolver.resolve!

    # Persist combat log entries
    @result.log_entries.each do |entry|
      @battle.combat_log_entries.create!(
        round_number: @battle.round_number || 1,
        sequence: @battle.next_sequence_for(@battle.round_number || 1),
        event_type: entry[:type].to_s,
        message: entry[:message],
        actor_id: entry[:actor_id],
        actor_name: entry[:actor_name],
        metadata: entry[:data]
      )
    end

    # Broadcast results
    broadcast_round_complete(@result)

    # Handle battle end if applicable
    if @result.battle_ended
      broadcast_battle_end(@result.winner_team)
    else
      # Start timer for next turn
      @battle.start_turn_timer!
    end
  end

  def broadcast_ready_state
    ActionCable.server.broadcast(
      @battle.broadcast_channel,
      {type: "opponent_ready", participant_id: @participant.id}
    )
  end

  def broadcast_round_complete(result)
    participants_data = @battle.battle_participants.alive.map do |p|
      [p.id, {
        current_hp: p.current_hp,
        max_hp: p.max_hp,
        current_mp: p.current_mp,
        max_mp: p.max_mp
      }]
    end.to_h

    ActionCable.server.broadcast(
      @battle.broadcast_channel,
      {
        type: "round_complete",
        round: @battle.round_number,
        combat_log: result.log_entries,
        participants: participants_data,
        timer_end_at: @battle.turn_timer_ends_at&.iso8601
      }
    )
  end

  def broadcast_battle_end(winner_team)
    ActionCable.server.broadcast(
      @battle.broadcast_channel,
      {
        type: "combat_ended",
        winner_team: winner_team,
        xp_gained: calculate_xp_reward,
        gold_gained: calculate_gold_reward
      }
    )
  end

  def calculate_flee_chance
    base_chance = 30
    agility = @participant.character&.stats&.get(:agility)&.to_i || 10
    base_chance + (agility * 0.5)
  end

  def end_battle_with_flee
    opponent_team = (@participant.team == "alpha") ? "beta" : "alpha"
    @battle.update!(status: :completed, winning_team: opponent_team, ended_at: Time.current)
    broadcast_battle_end(opponent_team)
  end

  def calculate_xp_reward
    return 0 unless @battle.completed?

    base_xp = 50
    opponent = @battle.battle_participants.where.not(character: current_character).first
    level_diff = (opponent&.npc_template&.level || opponent&.character&.level || 1) - (current_character.level || 1)

    (base_xp * (1 + level_diff * 0.1)).round.clamp(10, 500)
  end

  def calculate_gold_reward
    return 0 unless @battle.completed?

    opponent = @battle.battle_participants.where.not(character: current_character).first
    opponent_level = opponent&.npc_template&.level || opponent&.character&.level || 1

    (10 + opponent_level * 5).clamp(5, 200)
  end

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to battle_path(@battle), alert: message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("flash", partial: "shared/flash", locals: {type: "alert", message: message})
      end
    end
  end
end
