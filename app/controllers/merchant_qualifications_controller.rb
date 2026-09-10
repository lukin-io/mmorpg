# frozen_string_literal: true

class MerchantQualificationsController < ApplicationController
  before_action :ensure_active_character!

  def accept
    perform_step(:accept)
  end

  def pay
    perform_step(:pay)
  end

  def complete
    perform_step(:complete)
  end

  private

  def perform_step(step)
    authorize current_character, :manage_progression?
    result = Game::Shop::MerchantQualification.new(character: current_character).call(action: step)
    destination = step == :pay ? shop_path(mode: "licenses") : city_building_path("market")
    redirect_to destination, status: :see_other, **{result.success ? :notice : :alert => result.message}
  end
end
