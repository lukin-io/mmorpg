# frozen_string_literal: true

# Handles resource gathering from world map nodes
class GatheringController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_gathering_node, only: %i[show harvest]

  # GET /gathering/:id
  # Show gathering node details and options
  def show
    @profession_progress = current_character.profession_progresses
      .joins(:profession)
      .find_by(professions: {id: @gathering_node.profession_id})

    @can_harvest = can_harvest?
    @harvest_chance = calculate_harvest_chance
  end

  # POST /gathering/:id/harvest
  # Attempt to harvest from the node
  def harvest
    profession_progress = current_character.profession_progresses
      .joins(:profession)
      .find_by(professions: {id: @gathering_node.profession_id})

    unless profession_progress
      return respond_with_error("You don't have the required profession to harvest this resource.")
    end

    unless @gathering_node.available?
      return respond_with_error("This resource is not available. Check back later.")
    end

    party_size = current_character.current_party&.members&.count || 1

    resolver = Professions::GatheringResolver.new(
      progress: profession_progress,
      node: @gathering_node,
      party_size: party_size,
      rng: Random.new
    )

    begin
      result = resolver.harvest!

      if result[:success]
        # Add items to inventory
        add_rewards_to_inventory(result[:rewards])

        respond_to do |format|
          format.html do
            redirect_to world_path, notice: "Successfully gathered #{format_rewards(result[:rewards])}!"
          end
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("gathering-modal", partial: "gathering/result", locals: {
                success: true,
                rewards: result[:rewards],
                respawn_at: result[:respawn_at],
                xp_gained: @gathering_node.difficulty * 5
              }),
              turbo_stream.replace("flash", partial: "shared/flash", locals: {
                notice: "Successfully gathered #{format_rewards(result[:rewards])}!"
              })
            ]
          end
          format.json { render json: {success: true, rewards: result[:rewards], respawn_at: result[:respawn_at]} }
        end
      else
        respond_to do |format|
          format.html do
            redirect_to world_path, alert: "Gathering failed. Try again later."
          end
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("gathering-modal", partial: "gathering/result", locals: {
              success: false,
              cooldown: result[:cooldown],
              xp_gained: @gathering_node.difficulty
            })
          end
          format.json { render json: {success: false, cooldown: result[:cooldown]} }
        end
      end
    rescue Pundit::NotAuthorizedError => e
      respond_with_error(e.message)
    rescue => e
      respond_with_error(e.message)
    end
  end

  # GET /gathering/nodes
  # List available gathering nodes in current zone
  def nodes
    position = current_character.current_position
    return render json: {nodes: []} unless position&.zone

    nodes = GatheringNode.where(zone: position.zone).available
    render json: {nodes: nodes.map { |n| node_json(n) }}
  end

  private

  def set_gathering_node
    @gathering_node = GatheringNode.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_with_error("Resource node not found")
  end

  def can_harvest?
    return false unless @gathering_node.available?

    profession_progress = current_character.profession_progresses
      .find_by(profession_id: @gathering_node.profession_id)

    profession_progress.present?
  end

  def calculate_harvest_chance
    profession_progress = current_character.profession_progresses
      .find_by(profession_id: @gathering_node.profession_id)

    return 0 unless profession_progress

    base = 45
    skill_gap = profession_progress.skill_level - @gathering_node.difficulty
    location_bonus = profession_progress.location_bonus_for(@gathering_node.zone)
    party_size = current_character.current_party&.members&.count || 1
    group_bonus = (party_size > 1) ? (party_size - 1) * @gathering_node.group_bonus_percent : 0

    (base + (skill_gap * 4) + location_bonus + group_bonus).clamp(10, 95)
  end

  def add_rewards_to_inventory(rewards)
    return unless rewards.present?

    rewards.each do |reward|
      item_template = ItemTemplate.find_by(key: reward[:item_key])
      next unless item_template

      quantity = reward[:quantity] || 1
      quantity.times do
        current_character.inventory.add_item!(
          item_template,
          source: "Gathered from #{@gathering_node.resource_key}"
        )
      end
    end
  end

  def format_rewards(rewards)
    return "resources" unless rewards.present?

    rewards.map do |r|
      qty = r[:quantity] || 1
      "#{qty}x #{r[:item_key].to_s.titleize}"
    end.to_sentence
  end

  def node_json(node)
    {
      id: node.id,
      resource_key: node.resource_key,
      rarity: node.rarity_tier,
      difficulty: node.difficulty,
      available: node.available?,
      respawn_at: node.next_available_at&.iso8601
    }
  end

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to world_path, alert: message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: {alert: message})
      end
      format.json { render json: {success: false, error: message}, status: :unprocessable_entity }
    end
  end
end
