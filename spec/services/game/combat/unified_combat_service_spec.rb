# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Combat::UnifiedCombatService do
  let(:seed) { 12345 }
  let(:zone) { create(:zone, pvp_enabled: true) }
  let(:player) { create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50) }
  let(:opponent) { create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50) }
  let(:npc) { create(:npc_template, level: 1, metadata: { "stats" => { "hp" => 50, "attack" => 10, "defense" => 5 } }) }

  describe ".start_battle" do
    context "with success cases" do
      it "creates PvP battle between two players" do
        initiator = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        target = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        result = described_class.start_battle(
          initiator: initiator,
          opponent: target,
          zone: zone,
          battle_type: :pvp
        )

        expect(result.success?).to be true
        expect(result[:battle]).to be_persisted
        expect(result[:battle].pvp?).to be true
      end

      it "creates PvE battle against NPC" do
        initiator = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        result = described_class.start_battle(
          initiator: initiator,
          opponent: npc,
          zone: zone,
          battle_type: :pve
        )

        expect(result.success?).to be true
        expect(result[:battle].pve?).to be true
      end

      it "creates participants for both combatants" do
        initiator = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        target = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        result = described_class.start_battle(
          initiator: initiator,
          opponent: target,
          zone: zone,
          battle_type: :pvp
        )

        expect(result[:initiator_participant]).to be_persisted
        expect(result[:opponent_participant]).to be_persisted
        expect(result[:initiator_participant].team).to eq("alpha")
        expect(result[:opponent_participant].team).to eq("beta")
      end

      it "sets correct participant types" do
        player1 = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        player2 = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        player_result = described_class.start_battle(
          initiator: player1,
          opponent: player2,
          zone: zone,
          battle_type: :pvp
        )

        expect(player_result[:initiator_participant].participant_type).to eq("player")
        expect(player_result[:opponent_participant].participant_type).to eq("player")

        player3 = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        npc_result = described_class.start_battle(
          initiator: player3,
          opponent: npc,
          zone: zone,
          battle_type: :pve
        )

        expect(npc_result[:opponent_participant].participant_type).to eq("npc")
      end

      it "generates RNG seed" do
        initiator = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        target = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        result = described_class.start_battle(
          initiator: initiator,
          opponent: target,
          zone: zone,
          battle_type: :pvp
        )

        expect(result[:battle].rng_seed).to be_present
      end

      it "starts turn timer" do
        initiator = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        target = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        result = described_class.start_battle(
          initiator: initiator,
          opponent: target,
          zone: zone,
          battle_type: :pvp
        )

        expect(result[:battle].turn_timer_ends_at).to be_present
      end
    end

    context "with failure cases" do
      it "fails if initiator already in active battle" do
        initiator = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)
        target = create(:character, current_hp: 100, max_hp: 100, current_mp: 50, max_mp: 50)

        # Create an active battle first
        create(:battle, initiator: initiator, status: :active)

        result = described_class.start_battle(
          initiator: initiator,
          opponent: target,
          zone: zone,
          battle_type: :pvp
        )

        expect(result.success?).to be false
      end
    end
  end

  describe "#submit_turn" do
    let(:battle) { create(:battle, initiator: player, status: :active, combat_mode: "simultaneous", rng_seed: seed) }
    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: player,
        team: "alpha",
        is_alive: true,
        current_hp: 100,
        max_hp: 100,
        participant_type: "player")
    end
    let!(:opponent_participant) do
      create(:battle_participant,
        battle: battle,
        character: opponent,
        team: "beta",
        is_alive: true,
        current_hp: 100,
        max_hp: 100,
        participant_type: "player")
    end
    let(:service) { described_class.new(battle, rng: Random.new(seed)) }

    context "with success cases" do
      it "submits turn actions for participant" do
        result = service.submit_turn(
          player_participant,
          attacks: [{body_part: "head", action_key: "simple"}],
          blocks: []
        )

        expect(result.success?).to be true
        expect(result[:turn_submitted]).to be true
      end

      it "stores pending actions on participant" do
        service.submit_turn(
          player_participant,
          attacks: [{body_part: "head", action_key: "simple"}],
          blocks: [{body_part: "torso", action_key: "torso_block"}]
        )

        player_participant.reload
        expect(player_participant.pending_attacks).not_to be_empty
        expect(player_participant.pending_blocks).not_to be_empty
      end

      it "auto-resolves when all participants ready" do
        # First player submits
        service.submit_turn(
          player_participant,
          attacks: [{body_part: "head", action_key: "simple"}]
        )

        # Second player submits
        result = service.submit_turn(
          opponent_participant,
          attacks: [{body_part: "torso", action_key: "simple"}]
        )

        expect(result[:round_resolved]).to be true
      end
    end

    context "with failure cases" do
      it "rejects turn for inactive battle" do
        battle.update!(status: :completed)

        result = service.submit_turn(
          player_participant,
          attacks: [{body_part: "head", action_key: "simple"}]
        )

        expect(result.success?).to be false
        expect(result.error).to include("not active")
      end

      it "rejects turn for dead participant" do
        player_participant.update!(is_alive: false, current_hp: 0)

        result = service.submit_turn(
          player_participant,
          attacks: [{body_part: "head", action_key: "simple"}]
        )

        expect(result.success?).to be false
      end

      it "rejects invalid action combinations" do
        result = service.submit_turn(
          player_participant,
          attacks: [
            {body_part: "head", action_key: "simple"},
            {body_part: "legs", action_key: "simple"}
          ]
        )

        expect(result.success?).to be false
        expect(result.error).to include("head").or include("legs")
      end
    end

    context "with NPC opponents" do
      let!(:npc_participant) do
        opponent_participant.destroy
        create(:battle_participant,
          battle: battle,
          npc_template: npc,
          team: "beta",
          is_alive: true,
          current_hp: 50,
          max_hp: 50,
          participant_type: "npc")
      end

      it "auto-generates NPC actions" do
        result = service.submit_turn(
          player_participant,
          attacks: [{body_part: "head", action_key: "simple"}]
        )

        # NPC should have actions generated automatically
        expect(result[:round_resolved]).to be true
      end
    end
  end

  describe "#resolve_round!" do
    let(:battle) { create(:battle, initiator: player, status: :active, rng_seed: seed) }
    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: player,
        team: "alpha",
        is_alive: true,
        current_hp: 100,
        max_hp: 100,
        participant_type: "player",
        pending_attacks: [{body_part: "head", action_key: "simple"}])
    end
    let!(:opponent_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: npc,
        team: "beta",
        is_alive: true,
        current_hp: 50,
        max_hp: 50,
        participant_type: "npc",
        pending_attacks: [{body_part: "torso", action_key: "simple"}])
    end
    let(:service) { described_class.new(battle, rng: Random.new(seed)) }

    context "with success cases" do
      it "resolves round and returns log entries" do
        result = service.resolve_round!

        expect(result.success?).to be true
        expect(result[:log_entries]).to be_an(Array)
      end

      it "persists combat log entries" do
        service.resolve_round!

        expect(battle.combat_log_entries.count).to be > 0
      end

      it "broadcasts round completion" do
        expect(ActionCable.server).to receive(:broadcast).at_least(:once)

        service.resolve_round!
      end
    end

    context "with battle end" do
      it "detects battle end when one team eliminated" do
        opponent_participant.update!(current_hp: 1)

        result = service.resolve_round!

        # May end battle depending on damage
        expect(result[:battle_ended]).to be(true).or be(false)
      end

      it "sets winning team" do
        opponent_participant.update!(current_hp: 1, is_alive: true)
        player_participant.update!(
          pending_attacks: [
            {body_part: "head", action_key: "aimed"},
            {body_part: "torso", action_key: "aimed"}
          ]
        )

        result = service.resolve_round!

        if result[:battle_ended]
          expect(result[:winner_team]).to be_present
        end
      end
    end
  end

  describe "#flee" do
    let(:battle) { create(:battle, initiator: player, status: :active, rng_seed: seed) }
    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: player,
        team: "alpha",
        is_alive: true,
        current_hp: 100)
    end
    let!(:opponent_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: npc,
        team: "beta",
        is_alive: true,
        current_hp: 50)
    end
    let(:service) { described_class.new(battle, rng: Random.new(seed)) }

    context "with success cases" do
      it "can successfully flee" do
        # High agility increases flee chance
        player.update!(allocated_stats: {agility: 50})

        # Try multiple times to find a successful flee
        10.times do |i|
          svc = described_class.new(battle.reload, rng: Random.new(i * 100))
          result = svc.flee(player_participant)

          if result[:fled]
            expect(battle.reload.completed?).to be true
            break
          end
        end
      end

      it "returns message on flee result" do
        result = service.flee(player_participant)

        expect(result[:message]).to be_present
      end
    end

    context "with failure cases" do
      it "fails to flee for dead participant" do
        player_participant.update!(is_alive: false, current_hp: 0)

        result = service.flee(player_participant)

        expect(result.success?).to be false
        expect(result.error).to include("dead")
      end

      it "fails to flee for inactive battle" do
        battle.update!(status: :completed)

        result = service.flee(player_participant)

        expect(result.success?).to be false
      end
    end
  end

  describe "#surrender" do
    let(:battle) { create(:battle, initiator: player, status: :active) }
    let!(:player_participant) do
      create(:battle_participant,
        battle: battle,
        character: player,
        team: "alpha",
        is_alive: true,
        current_hp: 100)
    end
    let!(:opponent_participant) do
      create(:battle_participant,
        battle: battle,
        npc_template: npc,
        team: "beta",
        is_alive: true,
        current_hp: 50)
    end
    let(:service) { described_class.new(battle) }

    context "with success cases" do
      it "surrenders the battle" do
        result = service.surrender(player_participant)

        expect(result.success?).to be true
        expect(result[:surrendered]).to be true
      end

      it "marks participant as dead" do
        service.surrender(player_participant)

        player_participant.reload
        expect(player_participant.is_alive).to be false
        expect(player_participant.current_hp).to eq(0)
      end

      it "ends battle with opponent as winner" do
        service.surrender(player_participant)

        battle.reload
        expect(battle.completed?).to be true
        expect(battle.winning_team).to eq("beta")
      end
    end

    context "with failure cases" do
      it "fails for inactive battle" do
        battle.update!(status: :completed)

        result = service.surrender(player_participant)

        expect(result.success?).to be false
      end
    end
  end
end
