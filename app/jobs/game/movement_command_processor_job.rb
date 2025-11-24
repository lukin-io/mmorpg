# frozen_string_literal: true

module Game
  # MovementCommandProcessorJob drains queued movement commands through the authoritative queue.
  class MovementCommandProcessorJob < ApplicationJob
    queue_as :movement

    def perform(command_id)
      command = MovementCommand.find_by(id: command_id)
      return unless command

      Game::Movement::CommandQueue.new(character: command.character).process(command)
    end
  end
end
