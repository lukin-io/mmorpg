# frozen_string_literal: true

module Premium
  # Handles premium store purchases and artifacts.
  class ArtifactStore
    CATEGORIES = {
      cosmetic: "Cosmetics",
      mount: "Mounts",
      pet: "Pets",
      boost: "Boosts",
      convenience: "Convenience",
      storage: "Storage",
      title: "Titles"
    }.freeze

    ARTIFACTS = [
      {key: "wings_of_glory", name: "Wings of Glory", category: :cosmetic, price: 500, description: "Majestic golden wings", icon: "👼", unique: true, featured: true},
      {key: "shadow_cloak", name: "Shadow Cloak", category: :cosmetic, price: 300, description: "A mysterious dark cloak", icon: "🧥", unique: true},
      {key: "phoenix_mount", name: "Phoenix Mount", category: :mount, price: 1000, description: "Ride a blazing phoenix", icon: "🐦‍🔥", unique: true, featured: true},
      {key: "crystal_dragon", name: "Crystal Dragon", category: :pet, price: 750, description: "A shimmering companion", icon: "🐉", unique: true},
      {key: "xp_boost_7d", name: "XP Boost (7 Days)", category: :boost, price: 200, description: "+50% XP for 7 days", icon: "⚡", duration: "7 days"},
      {key: "gold_boost_7d", name: "Gold Boost (7 Days)", category: :boost, price: 200, description: "+50% Gold for 7 days", icon: "💰", duration: "7 days"},
      {key: "extra_bank_slots", name: "Bank Expansion", category: :storage, price: 150, description: "+20 bank slots", icon: "📦", unique: true},
      {key: "vip_title", name: "VIP Title", category: :title, price: 500, description: "Exclusive VIP title", icon: "👑", unique: true}
    ].freeze

    class << self
      def featured_items
        ARTIFACTS.select { |a| a[:featured] }
      end

      def find_artifact(key)
        ARTIFACTS.find { |a| a[:key] == key.to_s }
      end

      def user_owns?(user, artifact_key)
        user.premium_purchases.exists?(artifact_key: artifact_key)
      end
    end

    attr_reader :user, :character

    def initialize(user:, character: nil)
      @user = user
      @character = character || user.character
    end

    def purchase!(artifact_key:)
      artifact = self.class.find_artifact(artifact_key)
      return {success: false, error: "Item not found"} unless artifact
      return {success: false, error: "Already owned"} if artifact[:unique] && self.class.user_owns?(user, artifact_key)
      return {success: false, error: "Insufficient tokens"} if user.premium_tokens_balance < artifact[:price]

      ActiveRecord::Base.transaction do
        user.decrement!(:premium_tokens_balance, artifact[:price])
        user.premium_purchases.create!(
          artifact_key: artifact_key,
          artifact_name: artifact[:name],
          category: artifact[:category],
          price_paid: artifact[:price],
          expires_at: artifact[:duration] ? parse_duration(artifact[:duration]) : nil
        )

        apply_artifact_effects!(artifact)
      end

      {success: true, artifact: artifact}
    end

    def gift!(artifact_key:, recipient:)
      artifact = self.class.find_artifact(artifact_key)
      return {success: false, error: "Item not found"} unless artifact
      return {success: false, error: "Cannot gift to yourself"} if recipient == user
      return {success: false, error: "Recipient already owns"} if artifact[:unique] && self.class.user_owns?(recipient, artifact_key)
      return {success: false, error: "Insufficient tokens"} if user.premium_tokens_balance < artifact[:price]

      ActiveRecord::Base.transaction do
        user.decrement!(:premium_tokens_balance, artifact[:price])
        recipient.premium_purchases.create!(
          artifact_key: artifact_key,
          artifact_name: artifact[:name],
          category: artifact[:category],
          price_paid: artifact[:price],
          gifted_by: user,
          expires_at: artifact[:duration] ? parse_duration(artifact[:duration]) : nil
        )
      end

      {success: true, artifact: artifact, recipient: recipient}
    end

    private

    def parse_duration(duration_str)
      case duration_str
      when /(\d+) day/i then Time.current + Regexp.last_match(1).to_i.days
      when /(\d+) hour/i then Time.current + Regexp.last_match(1).to_i.hours
      else Time.current + 7.days
      end
    end

    def apply_artifact_effects!(artifact)
      case artifact[:category]
      when :mount
        character&.mounts&.create!(mount_key: artifact[:key], name: artifact[:name])
      when :pet
        character&.pet_companions&.create!(pet_key: artifact[:key], name: artifact[:name])
      when :title
        title = Title.find_or_create_by!(title_key: artifact[:key], name: artifact[:name], rarity: "legendary")
        character&.title_grants&.find_or_create_by!(title: title)
      when :storage
        character&.inventory&.increment!(:max_slots, 20)
      when :boost
        apply_boost!(artifact)
      end
    end

    def apply_boost!(artifact)
      boost_type = artifact[:key].include?("xp") ? :xp : :gold
      user.active_boosts.create!(
        boost_type: boost_type,
        multiplier: 1.5,
        expires_at: parse_duration(artifact[:duration])
      )
    end
  end
end
