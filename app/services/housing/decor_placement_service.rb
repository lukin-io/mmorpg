# frozen_string_literal: true

module Housing
  # DecorPlacementService coordinates furniture/trophy/storage placement within a housing plot.
  #
  # Usage:
  #   Housing::DecorPlacementService.new(plot:, actor: current_user).place!(
  #     name: "Forge",
  #     decor_type: :utility,
  #     placement: {x: 2, y: 4},
  #     metadata: {"station" => "crafting"}
  #   )
  #
  # Returns:
  #   HousingDecorItem or raises when slot limits would be exceeded.
  class DecorPlacementService
    TROPHY_PER_ROOM_LIMIT = 3

    def initialize(plot:, actor:)
      @plot = plot
      @actor = actor
    end

    def place!(attributes)
      authorize_plot!

      HousingDecorItem.transaction do
        enforce_limits!(attributes)
        plot.housing_decor_items.create!(attributes)
      end
    end

    def remove!(decor_item)
      authorize_plot!
      raise ArgumentError, "Decor item does not belong to plot" unless decor_item.housing_plot_id == plot.id

      decor_item.destroy!
    end

    private

    attr_reader :plot, :actor

    def authorize_plot!
      return if actor == plot.user || actor&.has_role?(:gm)

      raise Pundit::NotAuthorizedError, "Only plot owners or GMs can modify décor"
    end

    def enforce_limits!(attributes)
      case attributes[:decor_type].to_s
      when "trophy"
        limit = plot.room_slots * TROPHY_PER_ROOM_LIMIT
        if plot.housing_decor_items.trophy.count >= limit
          limit_violation!("Trophy limit reached (#{limit})")
        end
      when "storage"
        max_storage_items = [1, plot.storage_slots / 10].max
        if plot.housing_decor_items.where(decor_type: :storage).count >= max_storage_items
          limit_violation!("Storage chest limit reached (#{max_storage_items})")
        end
      end
    end

    def limit_violation!(message)
      record = plot.housing_decor_items.build
      record.errors.add(:base, message)
      raise ActiveRecord::RecordInvalid.new(record)
    end
  end
end
