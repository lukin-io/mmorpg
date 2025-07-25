class Character < ApplicationRecord
  belongs_to :user
  has_many :memberships, dependent: :destroy
has_many :guilds, through: :memberships

  validates :name, presence: true
validates :class_type, presence: true
validates :level, numericality: { greater_than_or_equal_to: 1 }

end
