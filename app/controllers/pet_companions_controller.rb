# frozen_string_literal: true

class PetCompanionsController < ApplicationController
  before_action :set_pet, only: :care

  def index
    @pet_companions = policy_scope(PetCompanion).where(user: current_user).includes(:pet_species)
    @care_tasks = Companions::CareTaskResolver::TASKS
  end

  def create
    species = PetSpecies.find(pet_params[:pet_species_id])
    pet = current_user.pet_companions.create!(pet_species: species, nickname: pet_params[:nickname])
    redirect_to pet_companions_path, notice: "#{pet.nickname || species.name} acquired."
  end

  def care
    authorize @pet, :update?
    resolver = Companions::CareTaskResolver.new(pet: @pet)
    result = resolver.perform!(params[:task])
    redirect_to pet_companions_path, notice: "#{@pet.nickname || @pet.pet_species.name} gained #{result[:bonding_xp]} bonding XP."
  rescue => e
    redirect_to pet_companions_path, alert: e.message
  end

  private

  def set_pet
    @pet = PetCompanion.find(params[:id])
    authorize @pet, :update?
  end

  def pet_params
    params.require(:pet_companion).permit(:pet_species_id, :nickname)
  end
end
