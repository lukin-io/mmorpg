# frozen_string_literal: true

module Game
  module Activity
    # Compact achievement chains (Mistwar-style tiers I → … → Legendary).
    # Progress is cumulative per kind; UI unlocks the next visible tier after prior claim/complete.
    class AchievementCatalog
      CHAINS = [
        # Kill bots
        {id: "kill_pack", kind: "kill_npc", step: 0, required: 10, tier: "I", name_ru: "Зачистка I", name_en: "Clearing I", rewards: {"nv" => 20, "xp" => 30}},
        {id: "kill_pack", kind: "kill_npc", step: 1, required: 50, tier: "II", name_ru: "Зачистка II", name_en: "Clearing II", rewards: {"nv" => 60, "xp" => 80}},
        {id: "kill_pack", kind: "kill_npc", step: 2, required: 200, tier: "III", name_ru: "Зачистка III", name_en: "Clearing III", rewards: {"nv" => 150, "xp" => 200}},
        {id: "kill_pack", kind: "kill_npc", step: 3, required: 1000, tier: "legendary", name_ru: "Зачистка: Легенда", name_en: "Clearing: Legend", rewards: {"nv" => 500, "xp" => 800}},

        # Chat talker
        {id: "chat_talker", kind: "chat_message", step: 0, required: 10, tier: "I", name_ru: "Говорун I", name_en: "Talker I", rewards: {"nv" => 15, "xp" => 20}},
        {id: "chat_talker", kind: "chat_message", step: 1, required: 50, tier: "II", name_ru: "Говорун II", name_en: "Talker II", rewards: {"nv" => 50, "xp" => 60}},
        {id: "chat_talker", kind: "chat_message", step: 2, required: 200, tier: "III", name_ru: "Говорун III", name_en: "Talker III", rewards: {"nv" => 120, "xp" => 150}},
        {id: "chat_talker", kind: "chat_message", step: 3, required: 1000, tier: "legendary", name_ru: "Говорун: Легенда", name_en: "Talker: Legend", rewards: {"nv" => 400, "xp" => 500}},

        # Arena
        {id: "arena_fight", kind: "arena_fight", step: 0, required: 5, tier: "I", name_ru: "Арена I", name_en: "Arena I", rewards: {"nv" => 30, "xp" => 40}},
        {id: "arena_fight", kind: "arena_fight", step: 1, required: 25, tier: "II", name_ru: "Арена II", name_en: "Arena II", rewards: {"nv" => 100, "xp" => 120}},
        {id: "arena_fight", kind: "arena_fight", step: 2, required: 100, tier: "III", name_ru: "Арена III", name_en: "Arena III", rewards: {"nv" => 250, "xp" => 300}},
        {id: "arena_fight", kind: "arena_fight", step: 3, required: 500, tier: "legendary", name_ru: "Арена: Легенда", name_en: "Arena: Legend", rewards: {"nv" => 800, "xp" => 1000}},

        # Instances
        {id: "instance_launch", kind: "instance_launch", step: 0, required: 3, tier: "I", name_ru: "Первые врата", name_en: "First Gates", rewards: {"nv" => 40, "xp" => 50}},
        {id: "instance_launch", kind: "instance_launch", step: 1, required: 15, tier: "II", name_ru: "Исследователь разломов", name_en: "Rift Explorer", rewards: {"nv" => 120, "xp" => 160}},
        {id: "instance_launch", kind: "instance_launch", step: 2, required: 50, tier: "III", name_ru: "Ходок бездны", name_en: "Abyss Walker", rewards: {"nv" => 300, "xp" => 400}},
        {id: "instance_launch", kind: "instance_launch", step: 3, required: 200, tier: "legendary", name_ru: "Разломы: Легенда", name_en: "Rifts: Legend", rewards: {"nv" => 900, "xp" => 1200}},

        # Shop / trade
        {id: "shop_purchase", kind: "shop_purchase", step: 0, required: 5, tier: "I", name_ru: "Торговец I", name_en: "Trader I", rewards: {"nv" => 15, "xp" => 20}},
        {id: "shop_purchase", kind: "shop_purchase", step: 1, required: 25, tier: "II", name_ru: "Торговец II", name_en: "Trader II", rewards: {"nv" => 50, "xp" => 70}},
        {id: "shop_purchase", kind: "shop_purchase", step: 2, required: 100, tier: "III", name_ru: "Торговец III", name_en: "Trader III", rewards: {"nv" => 150, "xp" => 200}},
        {id: "shop_purchase", kind: "shop_purchase", step: 3, required: 500, tier: "legendary", name_ru: "Торговец: Легенда", name_en: "Trader: Legend", rewards: {"nv" => 500, "xp" => 600}},

        # Travel / walk cells
        {id: "travel_steps", kind: "travel_step", step: 0, required: 20, tier: "I", name_ru: "Путник I", name_en: "Wanderer I", rewards: {"nv" => 20, "xp" => 25}},
        {id: "travel_steps", kind: "travel_step", step: 1, required: 100, tier: "II", name_ru: "Путник II", name_en: "Wanderer II", rewards: {"nv" => 70, "xp" => 90}},
        {id: "travel_steps", kind: "travel_step", step: 2, required: 500, tier: "III", name_ru: "Путник III", name_en: "Wanderer III", rewards: {"nv" => 200, "xp" => 250}},
        {id: "travel_steps", kind: "travel_step", step: 3, required: 2000, tier: "legendary", name_ru: "Путник: Легенда", name_en: "Wanderer: Legend", rewards: {"nv" => 700, "xp" => 900}},

        # Idle
        {id: "idle_tick", kind: "idle_tick", step: 0, required: 10, tier: "I", name_ru: "Сторож времени I", name_en: "Time Keeper I", rewards: {"nv" => 25, "xp" => 25}},
        {id: "idle_tick", kind: "idle_tick", step: 1, required: 50, tier: "II", name_ru: "Сторож времени II", name_en: "Time Keeper II", rewards: {"nv" => 80, "xp" => 80}},
        {id: "idle_tick", kind: "idle_tick", step: 2, required: 200, tier: "III", name_ru: "Сторож времени III", name_en: "Time Keeper III", rewards: {"nv" => 200, "xp" => 200}},
        {id: "idle_tick", kind: "idle_tick", step: 3, required: 1000, tier: "legendary", name_ru: "Сторож: Легенда", name_en: "Time Keeper: Legend", rewards: {"nv" => 600, "xp" => 600}},

        # Level ups
        {id: "level_up", kind: "level_up", step: 0, required: 5, tier: "I", name_ru: "Рост I", name_en: "Growth I", rewards: {"nv" => 30, "xp" => 0}},
        {id: "level_up", kind: "level_up", step: 1, required: 15, tier: "II", name_ru: "Рост II", name_en: "Growth II", rewards: {"nv" => 100, "xp" => 0}},
        {id: "level_up", kind: "level_up", step: 2, required: 30, tier: "III", name_ru: "Рост III", name_en: "Growth III", rewards: {"nv" => 250, "xp" => 0}},
        {id: "level_up", kind: "level_up", step: 3, required: 50, tier: "legendary", name_ru: "Рост: Легенда", name_en: "Growth: Legend", rewards: {"nv" => 1000, "xp" => 0}}
      ].freeze

      def self.chains_for(kind)
        CHAINS.select { |row| row[:kind].to_s == kind.to_s }
      end

      def self.all
        CHAINS
      end

      def self.by_id(id)
        CHAINS.select { |row| row[:id].to_s == id.to_s }.sort_by { |row| row[:step] }
      end
    end
  end
end
