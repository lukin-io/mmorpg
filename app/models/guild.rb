class Guild < ApplicationRecord
belongs_to :leader, class_name: "Character"
has_many :memberships, dependent: :destroy
has_many :characters, through: :memberships

validates :name, presence: true, uniqueness: true
end
