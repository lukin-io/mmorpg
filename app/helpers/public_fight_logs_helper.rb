# frozen_string_literal: true

module PublicFightLogsHelper
  # Both the live fight and its public history use this escaped presentation.
  # Names belong to their historical side even after a participant is defeated.
  def public_fight_log_message(entry, team_a:, team_b:)
    combat_log_message(entry.message, type: entry.log_type, team_a:, team_b:)
  end

  def combat_log_message(message, type:, team_a:, team_b:)
    side_classes = {}
    team_a.each { |participant| side_classes[participant.participant_name] = "nl-log-name--alpha" }
    team_b.each { |participant| side_classes[participant.participant_name] = "nl-log-name--beta" }
    names = side_classes.keys.reject(&:blank?).sort_by { |name| -name.length }
    tokens = names + [/-\d+/, /\((?:head|torso|stomach|legs)\)/,
      /has been defeated!|surrendered\.|Victory:|Fight finished\.|nothing found\./i,
      /«[^»]*»/]
    fragments = message.to_s.split(/(#{Regexp.union(tokens).source})/)

    safe_join(fragments.map do |fragment|
      css_class = side_classes[fragment]
      if css_class
        content_tag(:strong, fragment, class: "nl-log-name #{css_class}")
      elsif fragment.match?(/\A-\d+\z/)
        content_tag(:strong, fragment, class: "nl-log-damage#{" nl-log-damage--critical" if type == "critical"}")
      elsif fragment.match?(/\A\((head|torso|stomach|legs)\)\z/)
        content_tag(:span, fragment, class: "nl-log-body-part")
      elsif fragment.match?(/\A(?:has been defeated!|surrendered\.|Victory:|Fight finished\.|nothing found\.|«[^»]*»)\z/i)
        content_tag(:strong, fragment, class: ("nl-log-injury" if type == "injury"))
      else
        fragment
      end
    end)
  end
end
