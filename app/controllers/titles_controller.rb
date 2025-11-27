# frozen_string_literal: true

# Controller for managing character titles.
#
# Allows players to view earned titles and equip/unequip them.
#
class TitlesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  # GET /titles
  def index
    @earned_titles = current_character.title_grants.includes(:title).order(granted_at: :desc)
    @available_titles = Title.all.order(:rarity, :name)
    @equipped_title = current_character.equipped_title
  end

  # POST /titles/:id/equip
  def equip
    title_grant = current_character.title_grants.find_by!(title_id: params[:id])

    Titles::EquipService.new(character: current_character, title: title_grant.title).equip!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("equipped_title", partial: "titles/equipped", locals: {title: title_grant.title}),
          turbo_stream.replace("titles_list", partial: "titles/list", locals: {earned_titles: @earned_titles, equipped_title: title_grant.title}),
          turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :success, message: "Title equipped: #{title_grant.title.name}"})
        ]
      end
      format.html { redirect_to titles_path, notice: "Title equipped!" }
    end
  end

  # DELETE /titles/unequip
  def unequip
    Titles::EquipService.new(character: current_character).unequip!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("equipped_title", partial: "titles/equipped", locals: {title: nil}),
          turbo_stream.replace("titles_list", partial: "titles/list", locals: {earned_titles: current_character.title_grants.includes(:title), equipped_title: nil}),
          turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :info, message: "Title removed"})
        ]
      end
      format.html { redirect_to titles_path, notice: "Title removed!" }
    end
  end

  private

  def earned_titles
    @earned_titles ||= current_character.title_grants.includes(:title)
  end
end
