# frozen_string_literal: true

module Titles
  # EquipService activates a title for the given user, ensuring a single equipped title.
  #
  # Usage:
  #   Titles::EquipService.new(user: user).call(title: some_title, source: "achievement")
  #
  # Returns:
  #   TitleGrant that was equipped.
  class EquipService
    def initialize(user:)
      @user = user
    end

    def call(title:, source:)
      grant = user.title_grants.find_or_create_by!(title:, source:) do |record|
        record.granted_at = Time.current
      end
      user.title_grants.update_all(equipped: false)
      grant.update!(equipped: true)
      user.update!(active_title: title)
      grant
    end

    private

    attr_reader :user
  end
end
