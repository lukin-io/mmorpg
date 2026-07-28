# frozen_string_literal: true

module PublicFightLogsHelper
  # Adds the source log's side colors without trusting log text as HTML.
  # Every non-name fragment remains escaped by `safe_join`.
  def public_fight_log_message(entry, team_a:, team_b:)
    side_classes = {}
    team_a.each { |participant| side_classes[participant.participant_name] = "nl-log-name--alpha" }
    team_b.each { |participant| side_classes[participant.participant_name] = "nl-log-name--beta" }
    return entry.message if side_classes.empty?

    names = side_classes.keys.sort_by { |name| -name.length }
    pattern = Regexp.union(names)
    fragments = entry.message.to_s.split(/(#{pattern.source})/)

    safe_join(fragments.map do |fragment|
      css_class = side_classes[fragment]
      css_class ? content_tag(:span, fragment, class: "nl-log-name #{css_class}") : fragment
    end)
  end
end
