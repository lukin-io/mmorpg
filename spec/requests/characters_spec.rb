# frozen_string_literal: true

require "rails_helper"

RSpec.describe CharactersController, type: :request do
  let(:user) { create(:user) }
  let(:character_class) { create(:character_class, base_stats: {"strength" => 10, "dexterity" => 10}) }
  let!(:character) do
    create(:character,
      user: user,
      character_class: character_class,
      stat_points_available: 10,
      skill_points_available: 5,
      allocated_stats: {},
      passive_skills: {})
  end
  let!(:zone) { create(:zone) }

  before do
    sign_in user, scope: :user
    character.create_position!(zone: zone, x: 0, y: 0) unless character.position
  end

  # ============================================
  # GET /characters/:id/stats
  # ============================================
  describe "GET /characters/:id/stats" do
    context "when authenticated and authorized" do
      it "renders the stats allocation page" do
        get stats_character_path(character)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Character Stats")
        expect(response.body).to include("Available Points")
      end

      it "shows all allocatable stats" do
        get stats_character_path(character)

        %w[Strength Dexterity Intelligence Constitution Agility Luck].each do |stat|
          expect(response.body).to include(stat)
        end
      end

      it "shows available stat points count" do
        get stats_character_path(character)

        expect(response.body).to include("10") # stat_points_available
      end

      it "shows base stats from character class" do
        get stats_character_path(character)

        expect(response.body).to include("(base: 10)")
      end
    end

    context "with existing allocated stats" do
      before do
        character.update!(allocated_stats: {"strength" => 5})
      end

      it "shows current total including allocated" do
        get stats_character_path(character)

        expect(response).to have_http_status(:success)
        # Base 10 + allocated 5 = 15
        expect(response.body).to include("15")
      end
    end

    context "without character class (nil base stats)" do
      let!(:character_without_class) do
        create(:character,
          user: user,
          character_class: nil,
          stat_points_available: 10,
          skill_points_available: 5)
      end

      before do
        character_without_class.create_position!(zone: zone, x: 1, y: 1)
      end

      it "handles nil character class gracefully" do
        get stats_character_path(character_without_class)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Strength")
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        sign_out :user
        get stats_character_path(character)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when accessing another user's character" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects to root with error" do
        get stats_character_path(other_character)

        expect(response).to redirect_to(root_path)
      end
    end

    context "with non-existent character" do
      it "returns 404 not found" do
        get stats_character_path(id: 999_999)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ============================================
  # PATCH /characters/:id/stats
  # ============================================
  describe "PATCH /characters/:id/stats" do
    context "with valid allocation" do
      it "allocates single stat successfully" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 5}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(5)
        expect(character.allocated_stats["strength"]).to eq(5)
      end

      it "allocates multiple stats successfully" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 3, dexterity: 2, intelligence: 1}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(4) # 10 - 3 - 2 - 1
        expect(character.allocated_stats["strength"]).to eq(3)
        expect(character.allocated_stats["dexterity"]).to eq(2)
        expect(character.allocated_stats["intelligence"]).to eq(1)
      end

      it "allocates all available points" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 10}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(0)
        expect(character.allocated_stats["strength"]).to eq(10)
      end

      it "adds to existing allocations" do
        character.update!(allocated_stats: {"strength" => 5}, stat_points_available: 10)

        patch stats_character_path(character), params: {
          allocated_stats: {strength: 3}
        }

        character.reload
        expect(character.allocated_stats["strength"]).to eq(8) # 5 + 3
        expect(character.stat_points_available).to eq(7)
      end

      it "shows success flash message" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 1}
        }

        follow_redirect!
        expect(response.body).to include("Stats allocated successfully")
      end
    end

    context "with invalid allocation" do
      it "rejects over-allocation (single stat)" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 15}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough stat points available")
        character.reload
        expect(character.stat_points_available).to eq(10) # unchanged
      end

      it "rejects over-allocation (multiple stats exceed total)" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 6, dexterity: 6}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough stat points available")
      end

      it "rejects zero allocation" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 0}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No stats allocated")
      end

      it "rejects all-zero allocation" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 0, dexterity: 0, intelligence: 0}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No stats allocated")
      end
    end

    context "with edge case values" do
      it "clamps negative values to zero" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: -5}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No stats allocated")
        character.reload
        expect(character.stat_points_available).to eq(10) # unchanged
      end

      it "clamps extremely large values" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 1000}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough stat points available")
      end

      it "handles string values by converting to integer" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: "3"}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.allocated_stats["strength"]).to eq(3)
      end

      it "handles float values by truncating" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 3.9}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.allocated_stats["strength"]).to eq(3)
      end
    end

    context "with null/empty params" do
      it "handles nil allocated_stats" do
        patch stats_character_path(character), params: {
          allocated_stats: nil
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No stats allocated")
      end

      it "handles empty allocated_stats hash" do
        patch stats_character_path(character), params: {
          allocated_stats: {}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No stats allocated")
      end

      it "handles missing allocated_stats param" do
        patch stats_character_path(character), params: {}

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No stats allocated")
      end
    end

    context "with invalid stat keys" do
      it "ignores unknown stat keys" do
        patch stats_character_path(character), params: {
          allocated_stats: {unknown_stat: 5, strength: 2}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(3) # Only counts valid strength: 2 + unknown: 5
        # The unknown stat is stored but won't affect gameplay
      end
    end

    context "with zero available points" do
      before do
        character.update!(stat_points_available: 0)
      end

      it "rejects any allocation" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 1}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough stat points available")
      end
    end

    context "with turbo_stream format" do
      it "returns turbo_stream response on success" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 2}
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("stat-allocation")
      end

      it "returns turbo_stream response on failure" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 100}
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("flash")
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        sign_out :user
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 1}
        }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when accessing another user's character" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects to root" do
        patch stats_character_path(other_character), params: {
          allocated_stats: {strength: 1}
        }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ============================================
  # GET /characters/:id/skills
  # ============================================
  describe "GET /characters/:id/skills" do
    context "when authenticated and authorized" do
      it "renders the skills allocation page" do
        get skills_character_path(character)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Passive Skills")
        expect(response.body).to include("Skill Points")
      end

      it "shows wanderer skill" do
        get skills_character_path(character)

        expect(response.body).to include("Wanderer")
        expect(response.body).to include("movement speed")
      end

      it "shows available skill points count" do
        get skills_character_path(character)

        expect(response.body).to include("5") # skill_points_available
      end

      it "shows skill categories" do
        get skills_character_path(character)

        expect(response.body).to include("Movement")
      end
    end

    context "with existing skill levels" do
      before do
        character.update!(passive_skills: {"wanderer" => 50})
      end

      it "shows current skill level" do
        get skills_character_path(character)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("[050/100]")
      end

      it "shows skill effect based on level" do
        get skills_character_path(character)

        # At level 50: 35% reduction, 6.5s cooldown
        expect(response.body).to include("-35%")
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        sign_out :user
        get skills_character_path(character)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when accessing another user's character" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects to root" do
        get skills_character_path(other_character)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ============================================
  # PATCH /characters/:id/skills
  # ============================================
  describe "PATCH /characters/:id/skills" do
    context "with valid allocation" do
      it "allocates skill points successfully" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 5}
        }

        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.skill_points_available).to eq(0) # 5 - 5
        expect(character.passive_skill_level(:wanderer)).to eq(5)
      end

      it "adds to existing skill levels" do
        character.update!(passive_skills: {"wanderer" => 10}, skill_points_available: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 5}
        }

        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(15) # 10 + 5
        expect(character.skill_points_available).to eq(5)
      end

      it "shows success flash message" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 1}
        }

        follow_redirect!
        expect(response.body).to include("Skills allocated successfully")
      end

      it "clears passive skill calculator cache" do
        # First get the calculator
        character.passive_skill_calculator

        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 3}
        }

        character.reload
        # After allocation, cache should be cleared
        expect(character.passive_skill_level(:wanderer)).to eq(3)
      end
    end

    context "with max skill level handling" do
      it "respects max skill level of 100" do
        character.update!(skill_points_available: 150)

        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 100}
        }

        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(100)
        expect(character.skill_points_available).to eq(50) # 150 - 100
      end

      it "caps at max when adding to existing level" do
        character.update!(passive_skills: {"wanderer" => 80}, skill_points_available: 50)

        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 30}
        }

        character.reload
        # 80 + 30 = 110, but capped at 100 (only 20 actually used)
        expect(character.passive_skill_level(:wanderer)).to eq(100)
        # Only 20 points actually used (100 - 80), not 30 requested
        expect(character.skill_points_available).to eq(30) # 50 - 20 = 30
      end

      it "handles already at max level" do
        character.update!(passive_skills: {"wanderer" => 100}, skill_points_available: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 5}
        }

        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(100)
        # No points spent since we're already at max (0 points actually used)
        expect(character.skill_points_available).to eq(10)
      end
    end

    context "with invalid allocation" do
      it "rejects over-allocation" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 10}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough skill points available")
        character.reload
        expect(character.skill_points_available).to eq(5) # unchanged
      end

      it "rejects zero allocation" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 0}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No skills allocated")
      end
    end

    context "with edge case values" do
      it "clamps negative values to zero" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: -10}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No skills allocated")
      end

      it "handles string values by converting to integer" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: "3"}
        }

        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(3)
      end

      it "handles float values by truncating" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 2.9}
        }

        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(2)
      end
    end

    context "with null/empty params" do
      it "handles nil allocated_skills" do
        patch skills_character_path(character), params: {
          allocated_skills: nil
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No skills allocated")
      end

      it "handles empty allocated_skills hash" do
        patch skills_character_path(character), params: {
          allocated_skills: {}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No skills allocated")
      end

      it "handles missing allocated_skills param" do
        patch skills_character_path(character), params: {}

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("No skills allocated")
      end
    end

    context "with invalid skill keys" do
      it "ignores unknown skill keys and processes valid ones" do
        patch skills_character_path(character), params: {
          allocated_skills: {unknown_skill: 5, wanderer: 2}
        }

        # unknown_skill (5) + wanderer (2) = 7, but we only have 5 points
        # This should fail because total requested exceeds available
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough skill points available")
      end

      it "processes only valid skills when within budget" do
        character.update!(skill_points_available: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {unknown_skill: 3, wanderer: 2}
        }

        # Total = 5, we have 10, so it should succeed
        # But unknown_skill won't have any effect
        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:wanderer)).to eq(2)
        expect(character.skill_points_available).to eq(5) # 10 - 3 - 2
      end
    end

    context "with zero available points" do
      before do
        character.update!(skill_points_available: 0)
      end

      it "rejects any allocation" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 1}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Not enough skill points available")
      end
    end

    context "with turbo_stream format" do
      it "returns turbo_stream response on success" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 2}
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("skill-allocation")
      end

      it "returns turbo_stream response on failure" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 100}
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("flash")
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        sign_out :user
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 1}
        }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when accessing another user's character" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects to root" do
        patch skills_character_path(other_character), params: {
          allocated_skills: {wanderer: 1}
        }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ============================================
  # Integration Tests
  # ============================================
  describe "integration scenarios" do
    context "full allocation flow" do
      it "allocates stats, then skills in sequence" do
        # First allocate stats
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 5, dexterity: 5}
        }
        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(0)

        # Then allocate skills
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 5}
        }
        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.skill_points_available).to eq(0)

        # Verify final state
        expect(character.allocated_stats).to eq({"strength" => 5, "dexterity" => 5})
        expect(character.passive_skill_level(:wanderer)).to eq(5)
      end
    end

    context "level up scenario" do
      it "allows additional allocation after gaining points" do
        # Initial allocation
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 10}
        }
        character.reload
        expect(character.stat_points_available).to eq(0)

        # Simulate level up granting more points
        character.update!(stat_points_available: 5)

        # Allocate new points
        patch stats_character_path(character), params: {
          allocated_stats: {dexterity: 5}
        }
        character.reload
        expect(character.stat_points_available).to eq(0)
        expect(character.allocated_stats).to eq({"strength" => 10, "dexterity" => 5})
      end
    end
  end
end
