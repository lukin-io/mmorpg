module ApplicationHelper
  def online_reload_attributes
    return "" unless user_signed_in?

    %(
      data-online-reload-ping-url-value="#{session_ping_path}"
    ).squish.html_safe
  end

  # Tiny "i" popover next to routes, diggable actions, and buildings.
  def nl_info_tip(text, aria_label: nil)
    return "".html_safe if text.blank?

    label = aria_label.presence || I18n.t("game.common.info_tip_aria", default: "Info")
    tag.span(class: "nl-info-tip", data: {controller: "nl-info-tip"}) do
      safe_join([
        tag.button(
          "i",
          type: "button",
          class: "nl-info-tip__btn",
          "aria-label": label,
          data: {action: "nl-info-tip#toggle"}
        ),
        tag.span(text, class: "nl-info-tip__panel", hidden: true, data: {nl_info_tip_target: "panel"}, role: "note")
      ])
    end
  end

  def season_shell_title
    if @season_claimable.to_i.positive?
      I18n.t("game.season.shell_claim_title", count: @season_claimable)
    elsif @season_days_left.to_i.positive?
      I18n.t("game.season.shell_days_title", days: @season_days_left)
    else
      I18n.t("game.season.nav")
    end
  end
end
