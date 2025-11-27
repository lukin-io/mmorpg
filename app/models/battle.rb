# frozen_string_literal: true

# Battle persists PvE/PvP encounters, initiative order, and combat status.
class Battle < ApplicationRecord
  PVP_MODES = %w[duel skirmish arena clan].freeze

  enum :battle_type, {
    pve: 0,
    pvp: 1,
    arena: 2
  }

  enum :status, {
    pending: 0,
    active: 1,
    completed: 2
  }

  belongs_to :zone, optional: true
  belongs_to :initiator, class_name: "Character"
  has_many :battle_participants, dependent: :destroy
  has_many :combat_log_entries, dependent: :destroy
  has_one :combat_analytics_report, dependent: :destroy

  validates :turn_number, numericality: {greater_than: 0}
  validates :pvp_mode, inclusion: {in: PVP_MODES}, allow_nil: true

  before_create :generate_share_token

  # Find battle by share token for public access
  def self.find_by_share_token!(token)
    find_by!(share_token: token)
  end

  # Generate a shareable public URL
  def public_url
    return nil unless share_token.present?

    Rails.application.routes.url_helpers.public_battle_log_url(share_token, host: default_host)
  end

  # Shareable path (for internal links)
  def public_path
    return nil unless share_token.present?

    Rails.application.routes.url_helpers.public_battle_log_path(share_token)
  end

  def next_sequence_for(round_number)
    combat_log_entries.where(round_number:).maximum(:sequence).to_i + 1
  end

  def ladder_type
    return "arena" if battle_type == "arena"
    return pvp_mode if pvp_mode.present?

    nil
  end

  # Regenerate share token (for privacy)
  def regenerate_share_token!
    update!(share_token: generate_unique_token)
  end

  private

  def generate_share_token
    self.share_token ||= generate_unique_token
  end

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(12)
      break token unless Battle.exists?(share_token: token)
    end
  end

  def default_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end
end
