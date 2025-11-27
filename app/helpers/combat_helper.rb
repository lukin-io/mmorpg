# frozen_string_literal: true

module CombatHelper
  def entry_class_for(entry)
    return "" unless entry.is_a?(String)

    classes = ["combat-log-entry"]

    if entry.include?("CRITICAL")
      classes << "log-critical"
    elsif entry.include?("Victory") || entry.include?("defeated")
      classes << "log-victory"
    elsif entry.include?("Defeat") || entry.include?("slain")
      classes << "log-defeat"
    elsif entry.include?("flee") || entry.include?("escaped")
      classes << "log-flee"
    elsif entry.include?("attacks you")
      classes << "log-damage-received"
    elsif entry.include?("You attack")
      classes << "log-damage-dealt"
    elsif entry.include?("defensive")
      classes << "log-defend"
    end

    classes.join(" ")
  end
end
