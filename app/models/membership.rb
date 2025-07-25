class Membership < ApplicationRecord
belongs_to :guild
belongs_to :character

validates :character_id, uniqueness: { scope: :guild_id }

end
