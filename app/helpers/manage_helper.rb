# frozen_string_literal: true

module ManageHelper
  def pretty_json(value)
    JSON.pretty_generate(value.to_h)
  end

  def management_section_current?(key)
    controller_name == key.to_s
  end

  def management_boolean(value)
    value ? "Yes" : "No"
  end
end
