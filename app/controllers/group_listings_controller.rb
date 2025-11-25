# frozen_string_literal: true

class GroupListingsController < ApplicationController
  before_action :set_group_listing, only: [:edit, :update, :destroy]

  def index
    current_user.ensure_social_features!
    @group_listings = policy_scope(GroupListing).includes(:owner, :guild).order(updated_at: :desc)
    @group_listing = GroupListing.new
  end

  def new
    current_user.ensure_social_features!
    @group_listing = GroupListing.new
    authorize @group_listing
  end

  def create
    current_user.ensure_social_features!

    @group_listing = current_user.group_listings.new(group_listing_params)
    authorize @group_listing

    if @group_listing.save
      redirect_to group_listings_path, notice: "Listing published."
    else
      @group_listings = policy_scope(GroupListing).order(updated_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group_listing.update(group_listing_params)
      redirect_to group_listings_path, notice: "Listing updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group_listing.destroy
    redirect_to group_listings_path, notice: "Listing removed."
  end

  private

  def set_group_listing
    @group_listing = policy_scope(GroupListing).find(params[:id])
    authorize @group_listing
  end

  def group_listing_params
    params.require(:group_listing).permit(
      :title,
      :description,
      :listing_type,
      :status,
      :guild_id,
      :profession_id,
      :party_id,
      requirements: {},
      metadata: {}
    )
  end
end
