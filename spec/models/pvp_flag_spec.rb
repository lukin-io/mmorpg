# frozen_string_literal: true

require "rails_helper"

RSpec.describe PvpFlag, type: :model do
  describe "associations" do
    it "belongs to character" do
      flag = build(:pvp_flag)
      expect(flag.character).to be_present
    end
  end

  describe "validations" do
    it "requires flag_type" do
      flag = build(:pvp_flag, flag_type: nil)
      expect(flag).not_to be_valid
    end
  end

  describe "enums" do
    it "has correct flag_type values" do
      expect(described_class.flag_types).to eq({
        "voluntary" => 0,
        "hostile_action" => 1,
        "zone_flag" => 2,
        "faction_war" => 3
      })
    end
  end

  describe "scopes" do
    describe ".active" do
      it "includes flags without expiry" do
        flag = create(:pvp_flag, :voluntary)

        expect(described_class.active).to include(flag)
      end

      it "includes flags with future expiry" do
        flag = create(:pvp_flag, :hostile_action, expires_at: 1.hour.from_now)

        expect(described_class.active).to include(flag)
      end

      it "excludes expired flags" do
        flag = create(:pvp_flag, :expired)

        expect(described_class.active).not_to include(flag)
      end
    end

    describe ".expired" do
      it "includes expired flags" do
        flag = create(:pvp_flag, :expired)

        expect(described_class.expired).to include(flag)
      end

      it "excludes active flags" do
        flag = create(:pvp_flag, :voluntary)

        expect(described_class.expired).not_to include(flag)
      end
    end
  end

  describe "#active?" do
    it "returns true for flags without expiry" do
      flag = build(:pvp_flag, expires_at: nil)

      expect(flag.active?).to be true
    end

    it "returns true for flags with future expiry" do
      flag = build(:pvp_flag, expires_at: 1.hour.from_now)

      expect(flag.active?).to be true
    end

    it "returns false for expired flags" do
      flag = build(:pvp_flag, expires_at: 1.hour.ago)

      expect(flag.active?).to be false
    end
  end

  describe "#expired?" do
    it "returns false for flags without expiry" do
      flag = build(:pvp_flag, expires_at: nil)

      expect(flag.expired?).to be false
    end

    it "returns false for flags with future expiry" do
      flag = build(:pvp_flag, expires_at: 1.hour.from_now)

      expect(flag.expired?).to be false
    end

    it "returns true for expired flags" do
      flag = build(:pvp_flag, expires_at: 1.hour.ago)

      expect(flag.expired?).to be true
    end
  end

  describe "#time_remaining" do
    it "returns nil for permanent flags" do
      flag = build(:pvp_flag, expires_at: nil)

      expect(flag.time_remaining).to be_nil
    end

    it "returns seconds until expiry" do
      flag = build(:pvp_flag, expires_at: 5.minutes.from_now)

      expect(flag.time_remaining).to be_within(5).of(300)
    end

    it "returns 0 for expired flags" do
      flag = build(:pvp_flag, expires_at: 1.hour.ago)

      expect(flag.time_remaining).to eq(0)
    end
  end

  describe "#extend!" do
    it "extends the expiry time" do
      flag = create(:pvp_flag, :hostile_action, expires_at: 5.minutes.from_now)
      original_expiry = flag.expires_at

      flag.extend!(10.minutes)

      expect(flag.expires_at).to be > original_expiry
    end

    it "does nothing for permanent flags" do
      flag = create(:pvp_flag, :voluntary, expires_at: nil)

      flag.extend!(10.minutes)

      expect(flag.expires_at).to be_nil
    end
  end

  describe "#cancel!" do
    it "destroys voluntary flags" do
      flag = create(:pvp_flag, :voluntary)

      expect { flag.cancel! }.to change(described_class, :count).by(-1)
    end

    it "does not destroy non-voluntary flags" do
      flag = create(:pvp_flag, :hostile_action)

      expect { flag.cancel! }.not_to change(described_class, :count)
    end
  end

  describe ".cleanup_expired!" do
    it "deletes all expired flags" do
      create(:pvp_flag, :expired)
      create(:pvp_flag, :expired)
      active_flag = create(:pvp_flag, :voluntary)

      expect { described_class.cleanup_expired! }.to change(described_class, :count).by(-2)
      expect(described_class.all).to include(active_flag)
    end
  end
end
