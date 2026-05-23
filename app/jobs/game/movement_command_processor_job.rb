# frozen_string_literal: true

module Game
  # MovementCommandProcessorJob accepts server-offered movement commands.
  class MovementCommandProcessorJob < ApplicationJob
    queue_as :movement

    def perform(command_id)
      command = MovementCommand.find_by(id: command_id)
      return unless command

      Game::Movement::CommandQueue.new(character: command.character).process(command)
    end
  end
end
