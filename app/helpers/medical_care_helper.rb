# frozen_string_literal: true

module MedicalCareHelper
  def injury_remaining_time(injury, at: Time.current)
    remaining = [(injury.expires_at - at).ceil, 0].max
    format("%02d:%02d:%02d", remaining / 3600, remaining / 60 % 60, remaining % 60)
  end
end
