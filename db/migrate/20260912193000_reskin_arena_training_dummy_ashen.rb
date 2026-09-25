# frozen_string_literal: true

class ReskinArenaTrainingDummyAshen < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:npc_templates)

    say_with_time "reskin arena training dummy to Ashen RU" do
      execute <<~SQL.squish
        UPDATE npc_templates
        SET name = 'Пепельный манекен',
            dialogue = '*скрипит и покачивается*',
            metadata = COALESCE(metadata, '{}'::jsonb) ||
              '{"description":"Тренировочный манекен Пепельной Завесы.","source_name":"Пепельный манекен"}'::jsonb,
            updated_at = NOW()
        WHERE npc_key = 'arena_training_dummy'
           OR name = 'Training Dummy'
      SQL
    end
  end

  def down
    execute <<~SQL.squish
      UPDATE npc_templates
      SET name = 'Training Dummy',
          dialogue = '*creaks and sways*',
          updated_at = NOW()
      WHERE npc_key = 'arena_training_dummy'
    SQL
  end
end
