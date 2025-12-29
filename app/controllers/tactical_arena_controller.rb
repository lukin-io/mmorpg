# frozen_string_literal: true

# Controller for tactical grid-based arena combat.
#
# Tactical fights use a hex/square grid where positioning matters.
# Characters can move, attack adjacent enemies, or use ranged abilities.
#
# @example Start a tactical match
#   POST /tactical_arena/start
#
# @example Submit a move action
#   POST /tactical_arena/:id/move
#
class TacticalArenaController < ApplicationController
  include CurrentCharacterContext

  helper_method :my_turn?

  before_action :ensure_active_character!
  before_action :set_tactical_match, only: [:show, :move, :attack, :skill, :end_turn, :forfeit]

  # GET /tactical_arena
  def index
    @available_matches = TacticalMatch.pending.where.not(creator: current_character)
    @my_matches = TacticalMatch.where(creator: current_character).or(
      TacticalMatch.where(opponent: current_character)
    ).recent
  end

  # GET /tactical_arena/:id
  def show
    authorize @tactical_match
    @grid = @tactical_match.grid_state
    @current_turn = @tactical_match.current_turn_character
    @valid_moves = calculate_valid_moves if my_turn?
    @combat_log = @tactical_match.tactical_combat_log_entries.order(:created_at).last(20)
  end

  # POST /tactical_arena
  def create
    authorize TacticalMatch
    @tactical_match = TacticalMatch.new(
      creator: current_character,
      grid_size: params[:grid_size] || 8,
      turn_time_limit: params[:turn_time_limit] || 60,
      status: :pending
    )

    if @tactical_match.save
      @tactical_match.initialize_grid!
      redirect_to tactical_arena_path(@tactical_match), notice: "Tactical match created. Waiting for opponent."
    else
      redirect_to tactical_arena_index_path, alert: @tactical_match.errors.full_messages.to_sentence
    end
  end

  # POST /tactical_arena/:id/join
  def join
    @tactical_match = TacticalMatch.pending.find(params[:id])
    authorize @tactical_match

    if @tactical_match.add_opponent!(current_character)
      redirect_to tactical_arena_path(@tactical_match), notice: "Joined tactical match!"
    else
      redirect_to tactical_arena_index_path, alert: "Could not join match."
    end
  end

  # POST /tactical_arena/:id/move
  def move
    authorize @tactical_match, :play?
    return render_not_your_turn unless my_turn?

    target_x = params[:x].to_i
    target_y = params[:y].to_i

    result = Arena::TacticalCombat::MoveProcessor.new(
      match: @tactical_match,
      character: current_character,
      target_x: target_x,
      target_y: target_y
    ).execute!

    respond_to_action_result(result)
  end

  # POST /tactical_arena/:id/attack
  def attack
    authorize @tactical_match, :play?
    return render_not_your_turn unless my_turn?

    target_id = params[:target_id].to_i

    result = Arena::TacticalCombat::AttackProcessor.new(
      match: @tactical_match,
      attacker: current_character,
      target_id: target_id
    ).execute!

    respond_to_action_result(result)
  end

  # POST /tactical_arena/:id/skill
  def skill
    authorize @tactical_match, :play?
    return render_not_your_turn unless my_turn?

    result = Arena::TacticalCombat::SkillProcessor.new(
      match: @tactical_match,
      character: current_character,
      skill_id: params[:skill_id],
      target_x: params[:x]&.to_i,
      target_y: params[:y]&.to_i,
      target_id: params[:target_id]
    ).execute!

    respond_to_action_result(result)
  end

  # POST /tactical_arena/:id/end_turn
  def end_turn
    authorize @tactical_match, :play?
    return render_not_your_turn unless my_turn?

    @tactical_match.advance_turn!
    broadcast_turn_change

    redirect_to tactical_arena_path(@tactical_match)
  end

  # POST /tactical_arena/:id/forfeit
  def forfeit
    authorize @tactical_match, :play?

    @tactical_match.forfeit!(current_character)
    redirect_to tactical_arena_index_path, notice: "You forfeited the match."
  end

  private

  def set_tactical_match
    @tactical_match = TacticalMatch.find(params[:id])
  end

  def my_turn?
    @tactical_match.current_turn_character == current_character
  end

  def calculate_valid_moves
    Arena::TacticalCombat::MoveCalculator.new(
      match: @tactical_match,
      character: current_character
    ).valid_positions
  end

  def render_not_your_turn
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("notifications",
          partial: "shared/notification",
          locals: {type: :alert, message: "Not your turn!"})
      end
      format.html { redirect_to tactical_arena_path(@tactical_match), alert: "Not your turn!" }
    end
  end

  def respond_to_action_result(result)
    if result[:success]
      broadcast_grid_update
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("tactical_grid", partial: "tactical_arena/grid", locals: {match: @tactical_match}),
            turbo_stream.replace("combat_log", partial: "tactical_arena/combat_log", locals: {entries: @tactical_match.tactical_combat_log_entries.last(20)})
          ]
        end
        format.html { redirect_to tactical_arena_path(@tactical_match) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("notifications",
            partial: "shared/notification",
            locals: {type: :alert, message: result[:error]})
        end
        format.html { redirect_to tactical_arena_path(@tactical_match), alert: result[:error] }
      end
    end
  end

  def broadcast_grid_update
    ActionCable.server.broadcast(
      "tactical_match:#{@tactical_match.id}",
      {type: "grid_update", grid: @tactical_match.grid_state}
    )
  end

  def broadcast_turn_change
    ActionCable.server.broadcast(
      "tactical_match:#{@tactical_match.id}",
      {type: "turn_change", current_turn: @tactical_match.current_turn_character_id}
    )
  end
end
