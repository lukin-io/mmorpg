# frozen_string_literal: true

class AuctionListingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user&.verified_for_social_features?
  end

  def bid?
    user&.verified_for_social_features? && user != record.seller
  end

  class Scope < Scope
    def resolve
      scope.active
    end
  end
end
