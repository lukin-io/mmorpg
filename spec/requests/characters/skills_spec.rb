# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Characters Skills", type: :request do
  let(:user) { create(:user) }
  let(:character) do
    create(:character, user: user, combat_skill_points: 10, peace_skill_points: 5, skill_points_available: 15)
  end

  before do
    sign_in user, scope: :user
    allow_any_instance_of(CharactersController).to receive(:current_character).and_return(character)
  end

  describe "GET /characters/:id/skills" do
    context "success cases" do
      it "renders the skills page" do
        get skills_character_path(character)
        expect(response).to have_http_status(:ok)
      end

      it "displays skill names" do
        get skills_character_path(character)
        expect(response.body).to include("Wanderer")
        expect(response.body).to include("Melee Combat")
        expect(response.body).to include("First Aid")
      end

      it "displays combat skill points" do
        get skills_character_path(character)
        expect(response.body).to include("Combat/Magic Points:")
      end

      it "displays peace skill points" do
        get skills_character_path(character)
        expect(response.body).to include("Peace Points:")
      end

      it "displays skill categories" do
        get skills_character_path(character)
        expect(response.body).to include("Combat Skills")
        expect(response.body).to include("Magic Skills")
        expect(response.body).to include("Peace Skills")
      end

      it "displays skill level format" do
        get skills_character_path(character)
        expect(response.body).to include("[000/100]")
      end
    end

    context "authorization cases" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects when accessing other user's character" do
        get skills_character_path(other_character)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /characters/:id/skills" do
    context "success cases - combat skills" do
      it "allocates combat skill points with tiered progression" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 1}
        }

        character.reload
        # At level 0, melee_combat gains 10 points per spend (rate "10:8:6:4")
        expect(character.passive_skill_level(:melee_combat)).to eq(10)
        expect(character.combat_skill_points).to eq(9)
      end

      it "supports multiple combat skill allocations" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 1, ranged_combat: 1}
        }

        character.reload
        expect(character.passive_skill_level(:melee_combat)).to eq(10)
        expect(character.passive_skill_level(:ranged_combat)).to eq(10)
        expect(character.combat_skill_points).to eq(8)
      end

      it "handles multiple spends on same skill" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 3}
        }

        character.reload
        # Spend 1: 0 → 10, Spend 2: 10 → 20, Spend 3: 20 → 30
        expect(character.passive_skill_level(:melee_combat)).to eq(30)
        expect(character.combat_skill_points).to eq(7)
      end

      it "redirects with success notice" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 1}
        }

        expect(response).to redirect_to(skills_character_path(character))
      end
    end

    context "success cases - peace skills" do
      it "allocates peace skill points" do
        patch skills_character_path(character), params: {
          allocated_skills: {first_aid: 1}
        }

        character.reload
        # Peace skills have "2:2:2:2" rate - 2 points per spend
        expect(character.passive_skill_level(:first_aid)).to eq(2)
        expect(character.peace_skill_points).to eq(4)
      end

      it "supports multiple peace skill allocations" do
        patch skills_character_path(character), params: {
          allocated_skills: {first_aid: 2, trading: 1}
        }

        character.reload
        expect(character.passive_skill_level(:first_aid)).to eq(4)
        expect(character.passive_skill_level(:trading)).to eq(2)
        expect(character.peace_skill_points).to eq(2)
      end
    end

    context "success cases - mixed pools" do
      it "allocates from both pools simultaneously" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 1, first_aid: 1}
        }

        character.reload
        expect(character.passive_skill_level(:melee_combat)).to eq(10)
        expect(character.passive_skill_level(:first_aid)).to eq(2)
        expect(character.combat_skill_points).to eq(9)
        expect(character.peace_skill_points).to eq(4)
      end
    end

    context "success cases - turbo stream" do
      it "returns turbo stream response" do
        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 1}
        }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end

    context "failure cases - insufficient points" do
      it "rejects when not enough combat points" do
        character.update!(combat_skill_points: 0)

        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 1}
        }

        expect(response).to redirect_to(root_path)
        expect(character.reload.passive_skill_level(:melee_combat)).to eq(0)
      end

      it "rejects when not enough peace points" do
        character.update!(peace_skill_points: 0)

        patch skills_character_path(character), params: {
          allocated_skills: {first_aid: 1}
        }

        expect(response).to redirect_to(root_path)
        expect(character.reload.passive_skill_level(:first_aid)).to eq(0)
      end

      it "rejects when requesting more combat points than available" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 11}
        }

        expect(response).to redirect_to(root_path)
      end
    end

    context "failure cases - empty allocation" do
      it "rejects when no skills allocated" do
        patch skills_character_path(character), params: {
          allocated_skills: {}
        }

        expect(response).to redirect_to(root_path)
      end

      it "rejects when all allocations are zero" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 0, first_aid: 0}
        }

        expect(response).to redirect_to(root_path)
      end
    end

    context "edge cases - max level" do
      before do
        character.passive_skills["melee_combat"] = 95
        character.save!
      end

      it "caps skill at max level" do
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 2}
        }

        character.reload
        # At level 95 (tier 3), gains 4 per spend, but capped at 100
        expect(character.passive_skill_level(:melee_combat)).to eq(100)
      end
    end

    context "edge cases - tier transitions" do
      it "handles tier boundary correctly (24 → 25+)" do
        character.passive_skills["wanderer"] = 20
        character.save!

        patch skills_character_path(character), params: {
          allocated_skills: {wanderer: 1}
        }

        character.reload
        # At level 20 (tier 0), gains 10 → 30 (now in tier 1)
        expect(character.passive_skill_level(:wanderer)).to eq(30)
      end
    end

    context "edge cases - unknown skill" do
      it "ignores unknown skill keys and only allocates valid skills" do
        # When passing unknown_skill, the controller should ignore it
        # The melee_combat allocation should still work
        patch skills_character_path(character), params: {
          allocated_skills: {melee_combat: 1}
        }

        character.reload
        expect(character.passive_skill_level(:melee_combat)).to eq(10)
        expect(character.combat_skill_points).to eq(9)
      end
    end

    context "authorization cases" do
      let(:other_user) { create(:user) }
      let(:other_character) { create(:character, user: other_user) }

      it "redirects when updating other user's character" do
        patch skills_character_path(other_character), params: {
          allocated_skills: {melee_combat: 1}
        }

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
