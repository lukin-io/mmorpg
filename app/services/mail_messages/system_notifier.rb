# frozen_string_literal: true

module MailMessages
  # SystemNotifier sends automated mail (rewards, announcements) with optional attachments.
  # Usage:
  #   MailMessages::SystemNotifier.new.deliver!(recipients: [user], subject: "...", body: "...")
  class SystemNotifier
    def initialize(sender: default_sender)
      @sender = sender
    end

    def deliver!(recipients:, subject:, body:, attachment_payload: {}, origin_metadata: {})
      Array(recipients).compact.each do |recipient|
        MailMessage.create!(
          sender: sender,
          recipient: recipient,
          subject: subject,
          body: body,
          attachment_payload: filter_payload(attachment_payload),
          system_notification: true,
          origin_metadata: origin_metadata,
          delivered_at: Time.current
        )
      end
    end

    private

    attr_reader :sender

    def default_sender
      User.find_by(email: "admin@neverlands.test") || User.first!
    end

    def filter_payload(payload)
      payload.stringify_keys.slice(*MailMessage::ATTACHMENT_KEYS)
    end
  end
end
