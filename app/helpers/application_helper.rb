module ApplicationHelper
  def idle_tracker_attributes
    return "" unless user_signed_in?

    %(
      data-controller="idle-tracker"
      data-idle-tracker-ping-url-value="#{session_ping_path}"
    ).squish.html_safe
  end
end
