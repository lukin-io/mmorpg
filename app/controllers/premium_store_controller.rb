# frozen_string_literal: true

# Controller for premium artifact store.
#
# Cosmetics, convenience items, and boosts purchased with premium tokens.
#
class PremiumStoreController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  # GET /premium_store
  def index
    @categories = Premium::ArtifactStore::CATEGORIES
    @current_category = params[:category] || "all"
    @artifacts = load_artifacts
    @balance = current_user.premium_tokens_balance
    @featured = Premium::ArtifactStore.featured_items
  end

  # GET /premium_store/:id
  def show
    @artifact = Premium::ArtifactStore.find_artifact(params[:id])
    return redirect_to premium_store_index_path, alert: "Item not found" unless @artifact

    @can_purchase = can_purchase?(@artifact)
    @already_owned = already_owned?(@artifact)
  end

  # POST /premium_store/:id/purchase
  def purchase
    artifact = Premium::ArtifactStore.find_artifact(params[:id])
    return redirect_to premium_store_index_path, alert: "Item not found" unless artifact

    result = Premium::ArtifactStore.new(user: current_user, character: current_character)
      .purchase!(artifact_key: artifact[:key])

    if result[:success]
      redirect_to premium_store_index_path, notice: "🎉 #{artifact[:name]} purchased!"
    else
      redirect_to premium_store_path(params[:id]), alert: result[:error]
    end
  end

  # POST /premium_store/:id/gift
  def gift
    artifact = Premium::ArtifactStore.find_artifact(params[:id])
    recipient = User.find_by(profile_name: params[:recipient_name])

    unless recipient
      return redirect_to premium_store_path(params[:id]), alert: "Recipient not found"
    end

    result = Premium::ArtifactStore.new(user: current_user, character: current_character)
      .gift!(artifact_key: artifact[:key], recipient: recipient)

    if result[:success]
      redirect_to premium_store_index_path, notice: "🎁 Gift sent to #{recipient.profile_name}!"
    else
      redirect_to premium_store_path(params[:id]), alert: result[:error]
    end
  end

  private

  def load_artifacts
    artifacts = Premium::ArtifactStore::ARTIFACTS

    if @current_category != "all"
      artifacts = artifacts.select { |a| a[:category] == @current_category }
    end

    artifacts.sort_by { |a| [-a[:featured].to_i, a[:price]] }
  end

  def can_purchase?(artifact)
    current_user.premium_tokens_balance >= artifact[:price]
  end

  def already_owned?(artifact)
    return false unless artifact[:unique]

    Premium::ArtifactStore.user_owns?(current_user, artifact[:key])
  end
end
