# frozen_string_literal: true

class CraftingJobCompletionJob < ApplicationJob
  include ActionView::RecordIdentifier

  queue_as :default

  def perform(job_id)
    job = CraftingJob.find_by(id: job_id)
    return unless job
    return unless job.queued? || job.in_progress?

    job.update!(status: :in_progress) if job.queued?
    outcome = Professions::CraftingOutcomeResolver.new(job: job).call
    broadcast_update(job)
    broadcast_notification(job, outcome)
  end

  private

  def broadcast_update(job)
    Turbo::StreamsChannel.broadcast_replace_later_to(
      ["crafting_jobs", job.character_id],
      target: dom_id(job),
      partial: "crafting_jobs/job",
      locals: {job: job}
    )
  end

  def broadcast_notification(job, outcome)
    message =
      if job.completed?
        "Finished crafting #{job.recipe.name} (#{outcome.quality_tier.titleize})"
      else
        "Crafting attempt failed for #{job.recipe.name}"
      end

    Turbo::StreamsChannel.broadcast_append_later_to(
      notification_stream(job.user),
      target: notification_dom_id(job.user),
      partial: "shared/notification",
      locals: {message: message}
    )
  end

  def notification_stream(user)
    ["notifications", user.id]
  end

  def notification_dom_id(user)
    dom_id(user, :notifications)
  end
end
