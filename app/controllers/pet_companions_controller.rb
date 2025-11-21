# frozen_string_literal: true

class PetCompanionsController < ApplicationController
  def index
    @pet_companions = policy_scope(PetCompanion).where(user: current_user).includes(:pet_species)
  end

  def create
    species = PetSpecies.find(pet_params[:pet_species_id])
    pet = current_user.pet_companions.create!(pet_species: species, nickname: pet_params[:nickname])
    redirect_to pet_companions_path, notice: "#{pet.nickname || species.name} acquired."
  end

  private

  def pet_params
    params.require(:pet_companion).permit(:pet_species_id, :nickname)
  end
end

