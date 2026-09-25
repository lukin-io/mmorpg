# frozen_string_literal: true

class QuestsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  def index
    @entries = Game::Quests::Journal.new(character: current_character).entries
    status = params[:status].to_s.presence
    if status.present? && %w[available active ready locked completed].include?(status)
      @entries = @entries.select do |entry|
        ready = entry[:status] == "active" && entry[:progress].to_i >= entry[:target].to_i
        effective = ready ? "ready" : entry[:status].to_s
        effective == status
      end
    end
  end

  def accept
    result = Game::Quests::Journal.new(character: current_character).accept!(params[:id])
    redirect_after_mutation(result)
  end

  def turn_in
    result = Game::Quests::Journal.new(character: current_character).turn_in!(params[:id])
    redirect_after_mutation(result)
  end

  private

  def redirect_after_mutation(result)
    path_opts = result.success ? {} : {quest_denied: 1}
    redirect_to quests_path(**path_opts), status: :see_other, **flash_for(result)
  end

  def flash_for(result)
    result.success ? {notice: result.message} : {alert: result.message}
  end
end
