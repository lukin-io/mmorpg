# frozen_string_literal: true

class InstancesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  layout "game"

  def index
    @tab = %w[dungeon raid].include?(params[:tab].to_s) ? params[:tab].to_s : "dungeon"
    @entries = @tab == "raid" ? Game::Instances::Catalog.raids : Game::Instances::Catalog.dungeons
  end

  def launch
    kind = params[:kind].to_s
    id = params[:id].to_s
    result = Game::Instances::Launch.new(character: current_character, instance_kind: kind, instance_id: id).call
    if result.success?
      redirect_to arena_match_path(result.match), notice: result.message, status: :see_other
    else
      redirect_to instances_path(tab: kind == "raid" ? "raid" : "dungeon"), alert: result.message, status: :see_other
    end
  end
end
