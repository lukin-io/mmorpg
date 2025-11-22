# frozen_string_literal: true

module Admin
  module LiveOps
    class EventsController < Admin::BaseController
      def index
        authorize ::LiveOps::Event
        @events = policy_scope(::LiveOps::Event).order(created_at: :desc)
        @event = ::LiveOps::Event.new
      end

      def create
        @event = ::LiveOps::Event.new(event_params.merge(requested_by: current_user))
        authorize @event

        if @event.save
          @event.execute! if params[:execute_now].present?
          redirect_to admin_live_ops_events_path, notice: "Live Ops event queued."
        else
          @events = policy_scope(::LiveOps::Event).order(created_at: :desc)
          render :index, status: :unprocessable_entity
        end
      end

      def update
        event = policy_scope(::LiveOps::Event).find(params[:id])
        authorize event

        event.execute!
        redirect_to admin_live_ops_events_path, notice: "Event executed."
      rescue => e
        redirect_to admin_live_ops_events_path, alert: e.message
      end

      private

      def event_params
        permitted = params.require(:live_ops_event).permit(:event_type, :severity, :notes, :payload)
        permitted[:payload] = parse_payload(permitted[:payload])
        permitted
      end

      def parse_payload(value)
        return {} if value.blank?

        JSON.parse(value)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
