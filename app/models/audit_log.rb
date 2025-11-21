# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true
end
