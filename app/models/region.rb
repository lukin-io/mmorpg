class Region < ApplicationRecord
validates :name, presence: true, uniqueness: true
validates :x_coord, :y_coord, numericality: { only_integer: true }

end
