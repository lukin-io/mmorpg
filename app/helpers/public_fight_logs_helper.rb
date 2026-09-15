# frozen_string_literal: true

module PublicFightLogsHelper
  # Both the live fight and its public history use this escaped presentation.
  # Names belong to their historical side even after a participant is defeated.
  def public_fight_log_message(entry, team_a:, team_b:)
    message = entry.message.to_s
    message = "#{message}." unless message.end_with?(".", "!", "?")
    combat_log_message(message, type: entry.log_type, team_a:, team_b:, show_levels: true)
  end

  # Only adjacent outcomes from the same actor/round become one paragraph.
  # System/turn-submission messages keep their own row; original order persists.
  def public_fight_log_paragraphs(entries)
    entries.chunk do |entry|
      if entry.actor_id.present? && !entry.log_type.in?(%w[system action injury experience])
        [entry.round_number, entry.actor_type, entry.actor_id, entry.occurred_at_or_created_at.strftime("%H:%M")]
      else
        [:entry, entry.id]
      end
    end.map(&:last)
  end

  def combat_log_message(message, type:, team_a:, team_b:, show_levels: false)
    side_classes = {}
    levels = (team_a + team_b).to_h { |participant| [participant.participant_name, participant.participant_level] } if show_levels
    team_a.each { |participant| side_classes[participant.participant_name] = "nl-log-name--alpha" }
    team_b.each { |participant| side_classes[participant.participant_name] = "nl-log-name--beta" }
    names = side_classes.keys.reject(&:blank?).sort_by { |name| -name.length }
    name_tokens = names.map { |name| /#{Regexp.escape(name)}(?:\[\d+\])?/ }
    tokens = name_tokens + [/-\d+/, /\((?:head|torso|stomach|legs)\)/,
      /has been defeated!|surrendered\.|Victory:|Fight finished\.|nothing found\./i,
      /«[^»]*»/]
    fragments = message.to_s.split(/(#{Regexp.union(tokens).source})/)

    safe_join(fragments.map do |fragment|
      plain_name = fragment.sub(/\[\d+\]\z/, "")
      css_class = side_classes[plain_name]
      if css_class
        name = content_tag(:strong, plain_name, class: "nl-log-name #{css_class}")
        suffix = fragment.delete_prefix(plain_name)
        suffix = "[#{levels.fetch(plain_name)}]" if show_levels && suffix.empty?
        safe_join([name, suffix])
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
