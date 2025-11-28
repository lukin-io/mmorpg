class AddIsDefendingToBattleParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :battle_participants, :is_defending, :boolean, default: false
  end
end
