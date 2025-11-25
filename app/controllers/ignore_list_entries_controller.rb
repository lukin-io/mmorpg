# frozen_string_literal: true

class IgnoreListEntriesController < ApplicationController
  def index
    current_user.ensure_social_features!
    @entries = policy_scope(IgnoreListEntry).includes(:ignored_user).order(created_at: :desc)
    @ignore_list_entry = IgnoreListEntry.new
  end

  def create
    current_user.ensure_social_features!
    @ignore_list_entry = current_user.ignore_list_entries.new(ignore_list_entry_params)
    authorize @ignore_list_entry

    if @ignore_list_entry.save
      redirect_to ignore_list_entries_path, notice: "Player ignored."
    else
      @entries = policy_scope(IgnoreListEntry).includes(:ignored_user)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    entry = policy_scope(IgnoreListEntry).find(params[:id])
    authorize entry
    entry.destroy

    redirect_to ignore_list_entries_path, notice: "Player removed from ignore list."
  end

  private

  def ignore_list_entry_params
    params.require(:ignore_list_entry).permit(:ignored_user_id, :context, :notes)
  end
end
