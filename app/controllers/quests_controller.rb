# frozen_string_literal: true

class QuestsController < ApplicationController
  before_action :ensure_active_character!
  before_action :set_quest, only: [:show, :accept, :complete, :advance_story]
  before_action :set_assignment, only: [:show, :accept, :complete, :advance_story]

  def index
    authorize QuestAssignment
    refresh_storyline!
    refresh_dynamic_hooks!
    @filter = quest_filter
    base_scope = assignment_scope.includes(:quest)
    @filter_counts = filter_counts(base_scope)
    @quest_assignments = apply_filter(base_scope, @filter)
    @daily_slots = Game::Quests::DailyRotation.new(character: current_character).refresh!
    @weekly_assignments = Game::Quests::RepeatableQuestScheduler.new(character: current_character).refresh!
  end

  def show
    build_story_context!

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def accept
    gate_result = Game::Quests::QuestGateEvaluator.new(character: current_character, quest: @quest).call
    unless gate_result.allowed?
      return respond_with_gate_failure(gate_result)
    end

    @assignment.status = default_status_for(@quest)
    @assignment.started_at ||= Time.current if @assignment.in_progress?
    @assignment.save!
    build_story_context!

    respond_to do |format|
      format.html { redirect_to quest_path(@quest), notice: "Quest accepted." }
      format.turbo_stream
    end
  end

  def complete
    @assignment.update!(status: :completed, completed_at: Time.current)
    @reward_result = Game::Quests::RewardService.new(assignment: @assignment).claim!
    Analytics::QuestTracker.track_completion!(
      quest: @quest,
      character: current_character,
      duration_seconds: completion_duration_seconds
    )
    refresh_storyline!
    build_story_context!

    respond_to do |format|
      format.html { redirect_to quests_path, notice: "Quest completed!" }
      format.turbo_stream
    end
  rescue Game::Quests::RewardService::AlreadyClaimedError
    respond_to do |format|
      format.html { redirect_to quest_path(@quest), alert: "Rewards already claimed." }
      format.turbo_stream do
        flash.now[:alert] = "Rewards already claimed."
        build_story_context!
        render :complete
      end
    end
  end

  def advance_story
    runner = Game::Quests::StoryStepRunner.new(assignment: @assignment)
    @story_result = runner.call(choice_key: params[:choice_key])
    @assignment = @story_result.assignment
    build_story_context!(result: @story_result)

    respond_to do |format|
      format.html { redirect_to quest_path(@quest) }
      format.turbo_stream
    end
  rescue ArgumentError => e
    respond_to do |format|
      format.html { redirect_to quest_path(@quest), alert: e.message }
      format.turbo_stream do
        flash.now[:alert] = e.message
        build_story_context!
        render :advance_story
      end
    end
  end

  def daily
    authorize QuestAssignment
    @slots = Game::Quests::DailyRotation.new(character: current_character).refresh!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to quests_path }
    end
  end

  private

  def set_quest
    @quest = authorize Quest.active.find(params[:id])
  end

  def set_assignment
    @assignment = QuestAssignment.find_or_initialize_by(quest: @quest, character: current_character)
  end

  def refresh_storyline!
    return unless main_story_chain

    Game::Quests::StorylineProgression
      .new(character: current_character, quest_chain: main_story_chain)
      .unlock_available!
  end

  def refresh_dynamic_hooks!
    Game::Quests::DynamicQuestRefresher.new.refresh!(character: current_character)
  rescue StandardError => e
    Rails.logger.warn("Failed to refresh dynamic quests: #{e.message}")
  end

  def assignment_scope
    policy_scope(QuestAssignment)
      .where(character: current_character)
  end

  def apply_filter(scope, filter)
    filtered =
      case filter
      when "completed" then scope.completed
      when "repeatable" then scope.repeatable_templates
      else
        scope.active
      end
    filtered.includes(:quest).order(updated_at: :desc)
  end

  def filter_counts(scope)
    {
      active: scope.active.count,
      completed: scope.completed.count,
      repeatable: scope.repeatable_templates.count
    }
  end

  def quest_filter
    filter = params.fetch(:filter, "active").to_s
    return filter if %w[active completed repeatable].include?(filter)

    "active"
  end

  def build_story_context!(result: nil)
    steps = @quest.quest_steps.ordered
    @current_step = steps.find_by(position: @assignment.current_step_position) || steps.first
    @next_step = steps.find_by(position: @current_step.position + 1) if @current_step
    @story_result = result
    @map_overlay_pins = Game::Quests::MapOverlayPresenter.new(quest: @quest, character: current_character).pins
  end

  def respond_with_gate_failure(result)
    message = "Requirements not met: " + result.reasons.map { |failure|
      "#{failure[:type]} #{failure[:actual]}/#{failure[:required]}"
    }.join(", ")
    respond_to do |format|
      format.html { redirect_to quests_path, alert: message }
      format.turbo_stream do
        flash.now[:alert] = message
        build_story_context!
        render :accept
      end
    end
  end

  def completion_duration_seconds
    return 0 unless @assignment.started_at && @assignment.completed_at

    (@assignment.completed_at - @assignment.started_at).to_i
  end

  def default_status_for(quest)
    quest.repeatable_template? ? :pending : :in_progress
  end

  def main_story_chain
    @main_story_chain ||= QuestChain.find_by(key: "main_story")
  end
end
