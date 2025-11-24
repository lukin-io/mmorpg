# frozen_string_literal: true

class QuestsController < ApplicationController
  before_action :ensure_active_character!
  before_action :set_quest, only: [:show, :accept, :complete]

  def index
    authorize QuestAssignment
    if main_story_chain
      Game::Quests::ChainProgression.new(character: current_character, quest_chain: main_story_chain).unlock_available!
    end
    @quest_assignments =
      policy_scope(QuestAssignment)
        .where(character: current_character)
        .includes(:quest)
        .order(updated_at: :desc)
    @daily_slots = Game::Quests::DailyRotation.new(character: current_character).refresh!
  end

  def show
    @assignment = QuestAssignment.find_or_initialize_by(quest: @quest, character: current_character)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def accept
    assignment = QuestAssignment.find_or_initialize_by(quest: @quest, character: current_character)
    assignment.status = :in_progress
    assignment.started_at ||= Time.current
    assignment.save!

    respond_to do |format|
      format.html { redirect_to quest_path(@quest), notice: "Quest accepted." }
      format.turbo_stream { @assignment = assignment }
    end
  end

  def complete
    assignment = QuestAssignment.find_by!(quest: @quest, character: current_character)
    assignment.update!(status: :completed, completed_at: Time.current)

    respond_to do |format|
      format.html { redirect_to quests_path, notice: "Quest completed!" }
      format.turbo_stream { @assignment = assignment }
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
    @quest = authorize Quest.find(params[:id])
  end

  def main_story_chain
    QuestChain.find_by(key: "main_story")
  end
end
