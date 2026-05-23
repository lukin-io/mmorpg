# frozen_string_literal: true

require "rails_helper"

RSpec.describe Game::Movement::AcceptMove do
  include ActiveSupport::Testing::TimeHelpers

  let(:zone) { create(:zone, name: "Accept Move Plains", location_type: "outdoor", width: 10, height: 10) }
  let(:character) { create(:character) }
  let!(:position) { create(:character_position, character:, zone:, x: 5, y: 5) }

  after { travel_back }

  def offered_move(direction: "north", from_x: 5, from_y: 5, target_x: 5, target_y: 4)
    create(
      :movement_command,
      :offered,
      character:,
      zone:,
      direction:,
      from_x:,
      from_y:,
      target_x:,
      target_y:,
      predicted_x: target_x,
      predicted_y: target_y
    )
  end

  it "accepts a server-offered destination and starts timed travel" do
    travel_to(Time.zone.local(2026, 5, 10, 12, 0, 0)) do
      command = offered_move

      result = described_class.new(
        character:,
        action_key: command.action_key,
        target_x: command.target_x,
        target_y: command.target_y
      ).call

      expect(result.command.reload).to be_moving
      expect(result.command.started_at).to eq(Time.current)
      expect(result.command.ends_at).to eq(Time.current + 30.seconds)
      expect(result.position).to eq(position)
      expect(position.reload.x).to eq(5)
      expect(position.y).to eq(5)
    end
  end

  it "can issue and accept a fresh offer from direction fallback" do
    result = described_class.new(character:, direction: :east).call

    expect(result.command).to be_moving
    expect(result.command.direction).to eq("east")
    expect(result.command.target_position).to eq([6, 5])
  end

  it "cancels sibling destination offers when one move is accepted" do
    command = offered_move(direction: "north", target_x: 5, target_y: 4)
    sibling = offered_move(direction: "east", target_x: 6, target_y: 5)

    described_class.new(character:, action_key: command.action_key).call

    expect(command.reload).to be_moving
    expect(sibling.reload).to be_cancelled
    expect(sibling.processed_at).to be_present
  end

  it "rejects expired movement offers" do
    command = offered_move
    command.update!(created_at: MovementCommand::OFFER_TTL.ago - 1.second)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::TurnProcessor::MovementViolationError, /expired/)

    expect(command.reload).to be_offered
  end

  it "rejects offers that no longer match the current position" do
    command = offered_move
    position.update!(x: 6)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::TurnProcessor::MovementViolationError, /current position/)
  end

  it "rejects movement while another travel command is active" do
    command = offered_move
    create(:movement_command, :moving, character:, zone:, from_x: 5, from_y: 5, target_x: 5, target_y: 6)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::TurnProcessor::MovementViolationError, /already in progress/)
  end

  it "rejects offers whose target is no longer passable" do
    command = offered_move
    MapTileTemplate.create!(zone: zone.name, x: 5, y: 4, terrain_type: "outdoor", passable: false)

    expect {
      described_class.new(character:, action_key: command.action_key).call
    }.to raise_error(Game::Movement::TurnProcessor::MovementViolationError, /passable/)
  end
end
