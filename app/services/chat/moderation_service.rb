# frozen_string_literal: true

module Chat
  # Handles automated chat moderation, detecting violations and applying penalties.
  #
  # Detects:
  # - Profanity (via ProfanityFilter)
  # - Spam (rate limiting, repeated messages)
  # - Caps lock abuse
  # - Link spam
  # - Advertising
  # - Harassment patterns
  #
  # @example Check a message
  #   result = Chat::ModerationService.new.check_message(message)
  #   if result.violation?
  #     result.block_message? # true/false
  #     result.penalty_type   # :warning, :mute, :ban
  #   end
  #
  class ModerationService
    Result = Struct.new(
      :violation,
      :violation_type,
      :severity,
      :penalty,
      :block_message,
      :filtered_content,
      :reason,
      keyword_init: true
    ) do
      def violation?
        violation == true
      end

      def block_message?
        block_message == true
      end
    end

    # Violation severity levels
    SEVERITY = {
      low: 1,      # Warning only
      medium: 2,   # Temp mute (5-30 min)
      high: 3,     # Long mute (1-24 hours)
      critical: 4  # Immediate ban referral
    }.freeze

    # Penalty thresholds based on accumulated warnings
    PENALTY_THRESHOLDS = {
      3 => {type: :mute, duration: 5.minutes},
      5 => {type: :mute, duration: 30.minutes},
      8 => {type: :mute, duration: 2.hours},
      12 => {type: :mute, duration: 24.hours},
      15 => {type: :ban_referral, duration: nil}
    }.freeze

    # Rate limits
    RATE_LIMITS = {
      messages_per_minute: 10,
      messages_per_10_seconds: 4,
      identical_message_cooldown: 30.seconds,
      link_cooldown: 60.seconds
    }.freeze

    # Patterns
    PATTERNS = {
      caps_ratio_threshold: 0.7,
      min_length_for_caps_check: 10,
      repeated_char_threshold: 5,
      url_pattern: %r{https?://\S+|www\.\S+}i,
      advertising_keywords: %w[
        buy sell cheap discount promo code
        visit website click here free gold
        boost service powerleveling
      ],
      harassment_patterns: [
        /\b(kill yourself|kys|die)\b/i,
        /\b(retard|faggot|nigger)\b/i,
        /\bgo (fuck|die|kill)\b/i
      ]
    }.freeze

    attr_reader :profanity_filter

    def initialize(profanity_filter: Chat::ProfanityFilter.new)
      @profanity_filter = profanity_filter
    end

    # Check a single message for violations
    def check_message(message)
      user = message.user
      content = message.body

      # Check for various violations
      violations = []

      # 1. Profanity check
      profanity_result = check_profanity(content)
      violations << profanity_result if profanity_result

      # 2. Spam check (rate limiting)
      spam_result = check_spam(user, message.chat_channel)
      violations << spam_result if spam_result

      # 3. Duplicate message check
      duplicate_result = check_duplicate(user, content, message.chat_channel)
      violations << duplicate_result if duplicate_result

      # 4. Caps lock abuse
      caps_result = check_caps_abuse(content)
      violations << caps_result if caps_result

      # 5. Link/URL spam
      link_result = check_link_spam(user, content, message.chat_channel)
      violations << link_result if link_result

      # 6. Advertising detection
      ad_result = check_advertising(content)
      violations << ad_result if ad_result

      # 7. Harassment patterns
      harassment_result = check_harassment(content)
      violations << harassment_result if harassment_result

      # No violations
      return clean_result if violations.empty?

      # Get the most severe violation
      most_severe = violations.max_by { |v| SEVERITY[v[:severity]] || 0 }

      # Calculate penalty based on user's violation history
      penalty = calculate_penalty(user, most_severe)

      # Apply penalty if needed
      apply_penalty(user, penalty) if penalty[:type] != :warning

      # Record violation
      record_violation(user, most_severe, message)

      # Determine if message should be blocked
      block = should_block_message?(most_severe)

      # Filter content if not blocking
      filtered = block ? nil : filter_content(content, violations)

      Result.new(
        violation: true,
        violation_type: most_severe[:type],
        severity: most_severe[:severity],
        penalty: penalty,
        block_message: block,
        filtered_content: filtered,
        reason: most_severe[:reason]
      )
    end

    # Scan recent messages in a channel for patterns
    def scan_channel(channel, window: 1.hour)
      messages = channel.chat_messages
        .where("created_at > ?", window.ago)
        .includes(:user)

      violations_by_user = Hash.new { |h, k| h[k] = [] }

      messages.find_each do |message|
        result = check_message(message)
        violations_by_user[message.user_id] << result if result.violation?
      end

      # Apply penalties for accumulated violations
      violations_by_user.each do |user_id, violations|
        user = User.find(user_id)
        if violations.size >= 3
          apply_accumulated_penalty(user, violations)
        end
      end

      violations_by_user
    end

    private

    def clean_result
      Result.new(
        violation: false,
        violation_type: nil,
        severity: nil,
        penalty: {type: :none},
        block_message: false,
        filtered_content: nil,
        reason: nil
      )
    end

    def check_profanity(content)
      result = profanity_filter.filter(content)
      return nil unless result[:filtered]

      {
        type: :profanity,
        severity: result[:severity] || :medium,
        reason: "Profanity detected",
        matches: result[:matches]
      }
    end

    def check_spam(user, channel)
      recent_count = ChatMessage.where(user: user, chat_channel: channel)
        .where("created_at > ?", 1.minute.ago)
        .count

      if recent_count >= RATE_LIMITS[:messages_per_minute]
        return {
          type: :spam,
          severity: :medium,
          reason: "Rate limit exceeded (#{recent_count} messages/minute)"
        }
      end

      very_recent_count = ChatMessage.where(user: user, chat_channel: channel)
        .where("created_at > ?", 10.seconds.ago)
        .count

      if very_recent_count >= RATE_LIMITS[:messages_per_10_seconds]
        return {
          type: :spam,
          severity: :low,
          reason: "Rapid message spam detected"
        }
      end

      nil
    end

    def check_duplicate(user, content, channel)
      normalized = normalize_content(content)
      return nil if normalized.length < 5

      recent_messages = ChatMessage.where(user: user, chat_channel: channel)
        .where("created_at > ?", RATE_LIMITS[:identical_message_cooldown].ago)
        .pluck(:body)

      duplicates = recent_messages.count { |msg| normalize_content(msg) == normalized }

      if duplicates >= 2
        return {
          type: :duplicate,
          severity: :low,
          reason: "Repeated message detected"
        }
      end

      nil
    end

    def check_caps_abuse(content)
      return nil if content.length < PATTERNS[:min_length_for_caps_check]

      letters = content.gsub(/[^a-zA-Z]/, "")
      return nil if letters.empty?

      caps_ratio = letters.count("A-Z").to_f / letters.length

      if caps_ratio > PATTERNS[:caps_ratio_threshold]
        return {
          type: :caps_abuse,
          severity: :low,
          reason: "Excessive caps lock"
        }
      end

      # Check for repeated characters (AAAAAAAA)
      if content =~ /(.)\1{#{PATTERNS[:repeated_char_threshold]},}/i
        return {
          type: :caps_abuse,
          severity: :low,
          reason: "Repeated characters detected"
        }
      end

      nil
    end

    def check_link_spam(user, content, channel)
      return nil unless content =~ PATTERNS[:url_pattern]

      # Check if user can post links (level requirement or trust)
      unless user_can_post_links?(user)
        return {
          type: :link_spam,
          severity: :medium,
          reason: "New users cannot post links"
        }
      end

      # Check link cooldown
      recent_links = ChatMessage.where(user: user, chat_channel: channel)
        .where("created_at > ?", RATE_LIMITS[:link_cooldown].ago)
        .where("body ~ ?", PATTERNS[:url_pattern].source)
        .count

      if recent_links >= 2
        return {
          type: :link_spam,
          severity: :medium,
          reason: "Link posting too frequently"
        }
      end

      nil
    end

    def check_advertising(content)
      normalized = content.downcase

      ad_score = PATTERNS[:advertising_keywords].count do |keyword|
        normalized.include?(keyword)
      end

      if ad_score >= 3
        return {
          type: :advertising,
          severity: :high,
          reason: "Suspected advertising/gold selling"
        }
      end

      nil
    end

    def check_harassment(content)
      PATTERNS[:harassment_patterns].each do |pattern|
        if content =~ pattern
          return {
            type: :harassment,
            severity: :critical,
            reason: "Harassment/hate speech detected"
          }
        end
      end

      nil
    end

    def user_can_post_links?(user)
      # Users with characters above level 10 or 7+ days old can post links
      return true if user.created_at < 7.days.ago

      user.characters.any? { |c| c.level >= 10 }
    end

    def normalize_content(content)
      content.downcase.gsub(/\s+/, " ").strip
    end

    def calculate_penalty(user, violation)
      # Get user's warning count
      warning_count = user_warning_count(user)
      severity_multiplier = SEVERITY[violation[:severity]] || 1

      # Find applicable penalty threshold
      effective_warnings = warning_count + severity_multiplier

      PENALTY_THRESHOLDS.each do |threshold, penalty|
        if effective_warnings >= threshold
          return penalty.merge(warnings: effective_warnings)
        end
      end

      {type: :warning, duration: nil, warnings: effective_warnings}
    end

    def user_warning_count(user)
      # Count warnings in the last 24 hours
      ChatViolation.where(user: user)
        .where("created_at > ?", 24.hours.ago)
        .sum(:severity_points)
    end

    def apply_penalty(user, penalty)
      case penalty[:type]
      when :mute
        apply_mute(user, penalty[:duration])
      when :ban_referral
        create_ban_referral(user)
      end
    end

    def apply_mute(user, duration)
      user.update!(
        chat_muted_until: duration.from_now,
        chat_mute_reason: "Automated moderation: repeated violations"
      )

      Rails.logger.info("Chat mute applied to user #{user.id} for #{duration}")
    end

    def create_ban_referral(user)
      # Create a moderation ticket for manual review
      Moderation::Ticket.create!(
        subject_type: "User",
        subject_id: user.id,
        category: "chat_violation",
        status: :pending,
        priority: :high,
        description: "Automated referral: User has accumulated #{PENALTY_THRESHOLDS.keys.max} chat violations"
      )

      Rails.logger.warn("Ban referral created for user #{user.id}")
    end

    def apply_accumulated_penalty(user, violations)
      total_severity = violations.sum { |v| SEVERITY[v.severity] || 1 }

      if total_severity >= 6
        apply_mute(user, 30.minutes)
      elsif total_severity >= 4
        apply_mute(user, 10.minutes)
      end
    end

    def record_violation(user, violation, message)
      severity_points = SEVERITY[violation[:severity]] || 1

      ChatViolation.create!(
        user: user,
        chat_message: message,
        violation_type: violation[:type].to_s,
        severity: violation[:severity].to_s,
        severity_points: severity_points,
        reason: violation[:reason],
        metadata: {
          matches: violation[:matches],
          channel_id: message.chat_channel_id
        }
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to record violation: #{e.message}")
    end

    def should_block_message?(violation)
      # Block messages with high or critical severity
      %i[high critical].include?(violation[:severity])
    end

    def filter_content(content, violations)
      filtered = content.dup

      # Apply profanity filter
      profanity = violations.find { |v| v[:type] == :profanity }
      if profanity && profanity[:matches]
        profanity[:matches].each do |match|
          filtered.gsub!(/#{Regexp.escape(match)}/i, "*" * match.length)
        end
      end

      # Lowercase caps abuse
      caps = violations.find { |v| v[:type] == :caps_abuse }
      if caps
        filtered = filtered.downcase.capitalize
      end

      filtered
    end
  end

  # Model for tracking chat violations (create migration if needed)
  class ChatViolation < ApplicationRecord
    self.table_name = "chat_violations"

    belongs_to :user
    belongs_to :chat_message, optional: true

    validates :violation_type, :severity, :severity_points, presence: true
  end
end
