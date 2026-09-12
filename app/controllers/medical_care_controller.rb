# frozen_string_literal: true

class MedicalCareController < ApplicationController
  before_action :ensure_active_character!
  rescue_from Characters::TreatInjury::Unavailable, with: :unavailable

  def show
    @injuries = current_character.character_injuries.active_at(Time.current).order(:expires_at).limit(99)
    @requests = InjuryTreatment.joins(:character_injury).where(character_injuries: {character_id: current_character.id}, status: "pending")
      .where("injury_treatments.expires_at > ?", Time.current).includes(:healer, :character_injury).limit(99)
    @bags = current_character.inventory.inventory_items.includes(:item_template).select { |item| item.effect_modifiers["heals_injury"].present? }
  end

  def create
    patient = Character.find_by!(name: params[:patient_name].to_s)
    bag = current_character.inventory.inventory_items.find(params[:bag_id])
    injury = patient.character_injuries.active_at(Time.current).where(severity: bag.effect_modifiers["heals_injury"]).order(:created_at).first
    raise Characters::TreatInjury::Unavailable, "No matching injury" unless injury

    treatment = Characters::TreatInjury.new(healer: current_character, injury:, bag:).request!(price: params[:price].presence || 0)
    redirect_to medical_care_path, notice: treatment.status == "completed" ? "Injury healed." : "Treatment request sent.", status: :see_other
  end

  def accept
    treatment = owned_request
    Characters::TreatInjury.new(healer: treatment.healer, injury: treatment.character_injury)
      .accept!(treatment:, patient: current_character)
    redirect_to medical_care_path, notice: "Injury healed.", status: :see_other
  end

  def decline
    treatment = owned_request
    treatment.with_lock { treatment.update!(status: "declined") if treatment.status == "pending" }
    redirect_to medical_care_path, notice: "Treatment declined.", status: :see_other
  end

  private

  def owned_request
    InjuryTreatment.joins(:character_injury).where(character_injuries: {character_id: current_character.id}).find(params[:id])
  end

  def unavailable(error)
    redirect_to medical_care_path, alert: error.message, status: :see_other
  end
end
