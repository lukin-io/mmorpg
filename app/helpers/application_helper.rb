module ApplicationHelper
  def online_reload_attributes
    return "" unless user_signed_in?

    %(
      data-online-reload-ping-url-value="#{session_ping_path}"
    ).squish.html_safe
  end
end
