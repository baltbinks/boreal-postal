# frozen_string_literal: true

module API
  module V2
    class WebhooksController < BaseController

      def index
        server = find_server
        result = paginate(server.webhooks.order(:name))
        render json: {
          data: result[:data].map { |w| serialize_webhook(w) },
          pagination: result[:pagination]
        }
      end

      def show
        webhook = find_webhook
        render json: { data: serialize_webhook(webhook) }
      end

      def create
        server = find_server
        webhook = server.webhooks.new(webhook_params)
        webhook.events = params[:events] if params[:events].is_a?(Array)
        webhook.save!
        render json: { data: serialize_webhook(webhook) }, status: :created
      end

      def update
        webhook = find_webhook
        webhook.assign_attributes(webhook_params)
        webhook.events = params[:events] if params[:events].is_a?(Array)
        webhook.save!
        render json: { data: serialize_webhook(webhook) }
      end

      def destroy
        webhook = find_webhook
        webhook.destroy!
        head :no_content
      end

      def history
        webhook = find_webhook
        result = paginate(webhook.webhook_requests.order(created_at: :desc))
        render json: {
          data: result[:data].map { |wr| serialize_webhook_request(wr) },
          pagination: result[:pagination]
        }
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def find_webhook
        find_server.webhooks.find_by!(uuid: params[:uuid])
      end

      def webhook_params
        params.permit(:name, :url, :enabled, :all_events, :sign)
      end

      def serialize_webhook(webhook)
        {
          uuid: webhook.uuid,
          name: webhook.name,
          url: webhook.url,
          enabled: webhook.enabled,
          all_events: webhook.all_events,
          sign: webhook.sign,
          events: webhook.events,
          last_used_at: webhook.last_used_at&.iso8601,
          created_at: webhook.created_at&.iso8601,
          updated_at: webhook.updated_at&.iso8601
        }
      end

      def serialize_webhook_request(wr)
        {
          uuid: wr.uuid,
          event: wr.event,
          url: wr.url,
          attempts: wr.attempts,
          payload: wr.payload,
          error: wr.error,
          created_at: wr.created_at&.iso8601
        }
      end

    end
  end
end
