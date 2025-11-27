# frozen_string_literal: true

# Helpers for crafting job views.
module CraftingJobsHelper
  PROFESSION_ICONS = {
    "blacksmithing" => "⚒️",
    "tailoring" => "🧵",
    "alchemy" => "⚗️",
    "cooking" => "🍳",
    "enchanting" => "✨",
    "herbalism" => "🌿",
    "mining" => "⛏️",
    "fishing" => "🎣",
    "medical" => "💊"
  }.freeze

  def crafting_job_icon(job)
    profession_key = job.recipe.profession.key.downcase
    PROFESSION_ICONS[profession_key] || "📦"
  end

  def recipe_icon(recipe)
    profession_key = recipe.profession.key.downcase
    PROFESSION_ICONS[profession_key] || "📦"
  end
end

