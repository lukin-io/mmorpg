# frozen_string_literal: true

require "rails_helper"

RSpec.describe CharactersController, type: :request do
  let(:user) { create(:user) }
  let!(:character) do
    create(:character,
      user: user,
      stat_points_available: 10,
      combat_skill_points: 5,
      peace_skill_points: 5,
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
        expect(response.body).to include("Характеристики")
        expect(response.body).to include("Свободные очки")
      end

      it "shows all allocatable stats" do
        get stats_character_path(character)

        %w[Сила Ловкость Удача Здоровье Знания].each do |stat|
          expect(response.body).to include(stat)
        end
      end

      it "shows available stat points count" do
        get stats_character_path(character)

        expect(response.body).to include("10") # stat_points_available
      end

      it "shows Neverlands starter base stats" do
        get stats_character_path(character)

        expect(response.body).to include("(база: 1)")
      end
    end

    context "with existing allocated stats" do
      before do
        character.update!(allocated_stats: {"strength" => 5})
      end

      it "shows current total including allocated" do
        get stats_character_path(character)

        expect(response).to have_http_status(:success)
        # Base 1 + allocated 5 = 6
        expect(response.body).to include("6")
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
          allocated_stats: {strength: 3, dexterity: 2, vitality: 1}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(4) # 10 - 3 - 2 - 1
        expect(character.allocated_stats["strength"]).to eq(3)
        expect(character.allocated_stats["dexterity"]).to eq(2)
        expect(character.allocated_stats["vitality"]).to eq(1)
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
        expect(response.body).to include("Характеристики сохранены")
      end
    end

    context "with invalid allocation" do
      it "rejects over-allocation (single stat)" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 15}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Недостаточно свободных очков характеристик")
        character.reload
        expect(character.stat_points_available).to eq(10) # unchanged
      end

      it "rejects over-allocation (multiple stats exceed total)" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 6, dexterity: 6}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Недостаточно свободных очков характеристик")
      end

      it "rejects zero allocation" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 0}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Характеристики не выбраны")
      end

      it "rejects all-zero allocation" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 0, dexterity: 0, vitality: 0}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Характеристики не выбраны")
      end
    end

    context "with edge case values" do
      it "clamps negative values to zero" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: -5}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Характеристики не выбраны")
        character.reload
        expect(character.stat_points_available).to eq(10) # unchanged
      end

      it "clamps extremely large values" do
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 1000}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Недостаточно свободных очков характеристик")
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
        expect(response.body).to include("Характеристики не выбраны")
      end

      it "handles empty allocated_stats hash" do
        patch stats_character_path(character), params: {
          allocated_stats: {}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Характеристики не выбраны")
      end

      it "handles missing allocated_stats param" do
        patch stats_character_path(character), params: {}

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Характеристики не выбраны")
      end
    end

    context "with invalid stat keys" do
      it "ignores unknown stat keys" do
        patch stats_character_path(character), params: {
          allocated_stats: {unknown_stat: 5, strength: 2}
        }

        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(8)
        expect(character.allocated_stats).to eq({"strength" => 2})
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
        expect(response.body).to include("Недостаточно свободных очков характеристик")
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
        expect(response.body).to include("Умения")
        expect(response.body).to include("Боевые очки:")
        expect(response.body).to include("Мирные очки:")
      end

      it "shows source-backed skills" do
        get skills_character_path(character)

        expect(response.body).to include("Странник")
        expect(response.body).to include("Рукопашный бой")
      end

      it "shows available skill points count" do
        get skills_character_path(character)

        # Default character has combat_skill_points: 5 and peace_skill_points: 5
        expect(response.body).to include("Боевые очки:")
      end

      it "shows skill categories" do
        get skills_character_path(character)

        expect(response.body).to include("Боевые умения")
        expect(response.body).to include("Мирные умения")
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

      it "does not show uncaptured effect formulas" do
        get skills_character_path(character)

        expect(response.body).not_to include("-35%")
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
    # Note: This uses the new tiered progression system
    # - Рукопашный бой is a combat skill using the combat pool
    # - Each "spend" costs 1 combat_skill_point
    # - Progression rate "10:8:6:4" means: +10 at tier 0 (0-24), +8 at tier 1 (25-49), etc.

    context "with valid allocation" do
      before do
        character.update!(combat_skill_points: 5)
      end

      it "allocates skill points successfully with tiered progression" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}  # 1 spend = +10 at tier 0
        }

        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.combat_skill_points).to eq(4)  # 5 - 1
        expect(character.passive_skill_level(:unarmed_combat)).to eq(10)  # 0 + 10 (tier 0 rate)
      end

      it "adds to existing skill levels with tiered progression" do
        character.update!(passive_skills: {"unarmed_combat" => 20}, combat_skill_points: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}  # 1 spend at level 20 = +10 (still tier 0)
        }

        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(30)  # 20 + 10
        expect(character.combat_skill_points).to eq(9)
      end

      it "shows success flash message" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}
        }

        follow_redirect!
        expect(response.body).to include("Умения сохранены")
      end

      it "clears passive skill calculator cache" do
        # First get the calculator
        character.passive_skill_calculator

        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}
        }

        character.reload
        # After allocation, cache should be cleared
        expect(character.passive_skill_level(:unarmed_combat)).to eq(10)  # +10 at tier 0
      end
    end

    context "with max skill level handling" do
      it "respects max skill level of 100" do
        character.update!(combat_skill_points: 20)

        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 20}  # Would be 160+ if not capped
        }

        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(100)  # Capped at max
      end

      it "caps at max when adding to existing level" do
        character.update!(passive_skills: {"unarmed_combat" => 95}, combat_skill_points: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 2}  # At tier 3, +4 per spend
        }

        character.reload
        # 95 + 4 = 99, then 99 + 1 (capped) = 100
        expect(character.passive_skill_level(:unarmed_combat)).to eq(100)
      end

      it "handles already at max level" do
        character.update!(passive_skills: {"unarmed_combat" => 100}, combat_skill_points: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 2}
        }

        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(100)
        # Points are still spent even though skill is at max
        # Each spend at max level adds 0 points
      end
    end

    context "with invalid allocation" do
      it "rejects over-allocation" do
        character.update!(combat_skill_points: 1)

        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 10}  # Requesting 10 spends but only have 1
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Недостаточно боевых очков")
        character.reload
        expect(character.combat_skill_points).to eq(1)  # unchanged
      end

      it "rejects zero allocation" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 0}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Умения не выбраны")
      end
    end

    context "with edge case values" do
      before do
        character.update!(combat_skill_points: 5)
      end

      it "clamps negative values to zero" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: -10}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Умения не выбраны")
      end

      it "handles string values by converting to integer" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: "1"}
        }

        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(10)  # 1 spend = +10
      end

      it "handles float values by truncating" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1.9}
        }

        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(10)  # 1 spend = +10
      end
    end

    context "with null/empty params" do
      it "handles nil allocated_skills" do
        patch skills_character_path(character), params: {
          allocated_skills: nil
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Умения не выбраны")
      end

      it "handles empty allocated_skills hash" do
        patch skills_character_path(character), params: {
          allocated_skills: {}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Умения не выбраны")
      end

      it "handles missing allocated_skills param" do
        patch skills_character_path(character), params: {}

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Умения не выбраны")
      end
    end

    context "with invalid skill keys" do
      before do
        character.update!(combat_skill_points: 5)
      end

      it "ignores unknown skill keys and processes valid ones" do
        patch skills_character_path(character), params: {
          allocated_skills: {unknown_skill: 1, unarmed_combat: 1}
        }

        # unknown_skill is ignored, only unarmed_combat (1 spend) is processed
        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(10)
      end

      it "processes only valid skills when within budget" do
        character.update!(combat_skill_points: 10)

        patch skills_character_path(character), params: {
          allocated_skills: {unknown_skill: 3, unarmed_combat: 2}
        }

        # unknown_skill is ignored, unarmed_combat (2 spends) is processed
        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.passive_skill_level(:unarmed_combat)).to eq(20)  # 2 spends = 10 + 10
        expect(character.combat_skill_points).to eq(8)  # 10 - 2
      end
    end

    context "with zero available points" do
      before do
        character.update!(combat_skill_points: 0)
      end

      it "rejects any allocation" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}
        }

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Недостаточно боевых очков")
      end
    end

    context "with turbo_stream format" do
      before do
        character.update!(combat_skill_points: 5)
      end

      it "returns turbo_stream response on success" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}
        }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("skill-allocation")
      end

      it "returns turbo_stream response on failure" do
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 100}  # Too many
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
          allocated_skills: {unarmed_combat: 1}
        }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when accessing another user's character" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects to root" do
        patch skills_character_path(other_character), params: {
          allocated_skills: {unarmed_combat: 1}
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
      before do
        # Setup both stat points and combat skill points
        character.update!(stat_points_available: 10, combat_skill_points: 5)
      end

      it "allocates stats, then skills in sequence" do
        # First allocate stats
        patch stats_character_path(character), params: {
          allocated_stats: {strength: 5, dexterity: 5}
        }
        expect(response).to redirect_to(stats_character_path(character))
        character.reload
        expect(character.stat_points_available).to eq(0)

        # Then allocate skills (1 spend at tier 0 = +10 skill levels)
        patch skills_character_path(character), params: {
          allocated_skills: {unarmed_combat: 1}
        }
        expect(response).to redirect_to(skills_character_path(character))
        character.reload
        expect(character.combat_skill_points).to eq(4)  # 5 - 1

        # Verify final state
        expect(character.allocated_stats).to eq({"strength" => 5, "dexterity" => 5})
        expect(character.passive_skill_level(:unarmed_combat)).to eq(10)  # 1 spend = +10 at tier 0
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
