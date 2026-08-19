# frozen_string_literal: true

module Manage
  class AuditEventsController < ApplicationController
    def index
      scope = ManagementAuditEvent.includes(:actor).order(created_at: :desc)
      scope = scope.where(record_type: params[:record_type]) if params[:record_type].present?
      @audit_events = paginate(scope)
      @record_types = ManagementAuditEvent.distinct.order(:record_type).pluck(:record_type)
    end

    def show
      @audit_event = ManagementAuditEvent.includes(:actor).find(params[:id])
    end
  end
end
