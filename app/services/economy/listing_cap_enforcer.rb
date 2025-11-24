# frozen_string_literal: true

module Economy
  # ListingCapEnforcer limits the number of active auction listings per player per day.
  class ListingCapEnforcer
    MAX_LISTINGS_PER_DAY = 20

    def initialize(user:, scope: AuctionListing.all)
      @user = user
      @scope = scope
    end

    def enforce!(override: false)
      return if override

      recent_count = scope.where(seller: user)
        .where(created_at: 24.hours.ago..Time.current)
        .count
      return if recent_count < MAX_LISTINGS_PER_DAY

      raise Pundit::NotAuthorizedError, "Daily listing cap reached"
    end

    private

    attr_reader :user, :scope
  end
end
