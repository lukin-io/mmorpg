# frozen_string_literal: true

class GuildBankEntry < ApplicationRecord
  enum :entry_type, {
    deposit: 0,
    withdrawal: 1,
    purchase: 2,
    reward: 3
  }

  belongs_to :guild
  belongs_to :actor, class_name: "User"

  validates :currency_type, inclusion: {in: %w[gold silver premium_tokens]}
  validates :amount, numericality: {other_than: 0}
end
