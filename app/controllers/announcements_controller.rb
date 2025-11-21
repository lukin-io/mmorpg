# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  def index
    @announcements = Announcement.recent
    @announcement = Announcement.new
  end

  def create
    @announcement = Announcement.new(announcement_params)

    if @announcement.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to announcements_path, notice: "Announcement posted." }
      end
    else
      @announcements = Announcement.recent
      respond_to do |format|
        format.turbo_stream { render :index, status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  private

  def announcement_params
    params.require(:announcement).permit(:title, :body)
  end
end
