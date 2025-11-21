# frozen_string_literal: true

# Records privileged actions in the audit log for moderation-level transparency.
class AuditLogger
  def self.log(actor:, action:, target: nil, metadata: {})
    new(actor: actor, action: action, target: target, metadata: metadata).call
  end

  def initialize(actor:, action:, target:, metadata:)
    @actor = actor
    @action = action
    @target = target
    @metadata = metadata
  end

  def call
    AuditLog.create!(
      actor: actor,
      target: target,
      action: action,
      metadata: metadata
    )
  end

  private

  attr_reader :actor, :action, :target, :metadata
end
