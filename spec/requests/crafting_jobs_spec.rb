# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CraftingJobs", type: :request do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }
  let(:zone) { create(:zone, name: "Test Zone", biome: "city", width: 10, height: 10) }
  let!(:position) { create(:character_position, character: character, zone: zone, x: 5, y: 5) }

  before { sign_in user, scope: :user }

  describe "GET /crafting_jobs" do
    let!(:profession) { create(:profession, name: "Blacksmithing") }
    let!(:recipe) do
      create(:recipe,
        profession: profession,
        name: "Iron Sword",
        tier: 1,
        requirements: {
          "materials" => {"Iron Ingot" => 4, "Coal" => 1},
          "skill_level" => 5
        })
    end
    let!(:station) { create(:crafting_station, name: "Castleton Forge", station_archetype: "city") }

    it "renders successfully" do
      get crafting_jobs_path
      expect(response).to have_http_status(:success)
    end

    it "displays the crafting workshop header" do
      get crafting_jobs_path
      expect(response.body).to include("Crafting Workshop")
    end

    it "displays the exit to city link" do
      get crafting_jobs_path
      expect(response.body).to include("Exit to City")
    end

    context "recipe browser" do
      it "displays the recipe browser section" do
        get crafting_jobs_path
        expect(response.body).to include("Recipe Browser")
      end

      it "displays profession filter dropdown" do
        get crafting_jobs_path
        expect(response.body).to include("Profession")
        expect(response.body).to include("All Profession")
      end

      it "displays tier filter dropdown" do
        get crafting_jobs_path
        expect(response.body).to include("Tier")
        expect(response.body).to include("All Tier")
      end

      it "displays search input" do
        get crafting_jobs_path
        expect(response.body).to include("Search recipes")
      end
    end

    context "craft item form" do
      it "displays the craft item section" do
        get crafting_jobs_path
        expect(response.body).to include("Craft Item")
      end

      it "displays recipe dropdown with available recipes" do
        get crafting_jobs_path
        expect(response.body).to include("Iron Sword")
      end

      it "displays station dropdown with available stations" do
        get crafting_jobs_path
        expect(response.body).to include("Castleton Forge")
        expect(response.body).to include("(city)")
      end

      it "displays station archetype in dropdown" do
        get crafting_jobs_path
        # Verify station_archetype is shown, not archetype (which doesn't exist)
        expect(response.body).to include("(city)")
      end

      it "displays quantity input" do
        get crafting_jobs_path
        expect(response.body).to include("Quantity")
      end

      it "displays start crafting button" do
        get crafting_jobs_path
        expect(response.body).to include("Start Crafting")
      end
    end

    context "recipe cards" do
      it "displays recipe names" do
        get crafting_jobs_path
        expect(response.body).to include("Iron Sword")
      end

      it "displays recipe tier" do
        get crafting_jobs_path
        expect(response.body).to include("Tier 1")
      end

      it "displays required skill level from requirements" do
        get crafting_jobs_path
        expect(response.body).to include("Req. Skill")
        expect(response.body).to include("5")
      end

      it "displays profession name" do
        get crafting_jobs_path
        expect(response.body).to include("Blacksmithing")
      end

      it "displays recipe icon based on profession" do
        get crafting_jobs_path
        # Blacksmithing icon
        expect(response.body).to include("⚒️")
      end

      it "displays materials list" do
        get crafting_jobs_path
        expect(response.body).to include("Materials")
        expect(response.body).to include("Iron Ingot")
        expect(response.body).to include("x4")
        expect(response.body).to include("Coal")
        expect(response.body).to include("x1")
      end
    end

    context "with multiple recipes" do
      let!(:alchemy_profession) { create(:profession, name: "Alchemy") }
      let!(:potion_recipe) do
        create(:recipe,
          profession: alchemy_profession,
          name: "Health Potion",
          tier: 2,
          requirements: {
            "materials" => {"Herb" => 2},
            "skill_level" => 15
          })
      end

      it "displays all recipes" do
        get crafting_jobs_path
        expect(response.body).to include("Iron Sword")
        expect(response.body).to include("Health Potion")
      end

      it "displays different profession icons" do
        get crafting_jobs_path
        expect(response.body).to include("⚒️") # Blacksmithing
        expect(response.body).to include("⚗️") # Alchemy
      end
    end

    context "with multiple stations" do
      let!(:guild_station) { create(:crafting_station, name: "Guild Hall Loom", station_archetype: "guild_hall") }
      let!(:field_station) { create(:crafting_station, name: "Portable Kit", station_archetype: "field_kit") }

      it "displays all stations in dropdown" do
        get crafting_jobs_path
        expect(response.body).to include("Castleton Forge")
        expect(response.body).to include("Guild Hall Loom")
        expect(response.body).to include("Portable Kit")
      end

      it "displays station archetypes correctly" do
        get crafting_jobs_path
        expect(response.body).to include("(city)")
        expect(response.body).to include("(guild_hall)")
        expect(response.body).to include("(field_kit)")
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to login page" do
        get crafting_jobs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "with recipe that has no materials" do
      let!(:no_materials_recipe) do
        create(:recipe,
          profession: profession,
          name: "Basic Repair",
          tier: 1,
          requirements: {"skill_level" => 1})
      end

      it "renders successfully without errors" do
        get crafting_jobs_path
        expect(response).to have_http_status(:success)
      end

      it "displays the recipe" do
        get crafting_jobs_path
        expect(response.body).to include("Basic Repair")
      end
    end

    context "with recipe that uses default skill level" do
      let!(:default_skill_recipe) do
        create(:recipe,
          profession: profession,
          name: "Auto Skill Recipe",
          tier: 3,
          requirements: {"materials" => {}})
      end

      it "renders successfully" do
        get crafting_jobs_path
        expect(response).to have_http_status(:success)
      end

      it "displays tier-based default skill level" do
        get crafting_jobs_path
        # Tier 3 => skill level 30
        expect(response.body).to include("30")
      end
    end
  end

  describe "bug regressions" do
    let!(:profession) { create(:profession, name: "Blacksmithing") }
    let!(:recipe) do
      create(:recipe,
        profession: profession,
        requirements: {"materials" => {"Iron" => 2}, "skill_level" => 10})
    end
    let!(:station) { create(:crafting_station, station_archetype: "city") }

    describe "profession.key vs profession.name" do
      # Bug: CraftingJobsHelper was calling profession.key which doesn't exist
      # Fix: Changed to profession.name

      it "renders recipe icons without NoMethodError" do
        expect { get crafting_jobs_path }.not_to raise_error
        expect(response).to have_http_status(:success)
      end
    end

    describe "recipe.required_skill_level missing method" do
      # Bug: _recipe_card.html.erb called recipe.required_skill_level which didn't exist
      # Fix: Added required_skill_level method to Recipe model

      it "renders recipe cards without NoMethodError" do
        expect { get crafting_jobs_path }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "displays skill level in recipe cards" do
        get crafting_jobs_path
        expect(response.body).to include("Req. Skill")
      end
    end

    describe "materials hash iteration format" do
      # Bug: _recipe_card.html.erb iterated with mat["name"]/mat["quantity"]
      #      but materials is {name => quantity} hash, not array of hashes
      # Fix: Changed iteration to |item_name, quantity|

      it "renders materials list without TypeError" do
        expect { get crafting_jobs_path }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "displays materials correctly" do
        get crafting_jobs_path
        expect(response.body).to include("Iron")
        expect(response.body).to include("x2")
      end
    end

    describe "crafting_station.archetype vs station_archetype" do
      # Bug: index.html.erb called station.archetype which doesn't exist
      # Fix: Changed to station.station_archetype

      it "renders station dropdown without NoMethodError" do
        expect { get crafting_jobs_path }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "displays station archetype in dropdown" do
        get crafting_jobs_path
        expect(response.body).to include("(city)")
      end
    end
  end
end
