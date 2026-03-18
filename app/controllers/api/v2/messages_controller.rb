# frozen_string_literal: true

module API
  module V2
    class MessagesController < BaseController

      def index
        server = find_server
        page = (params[:page] || 1).to_i
        per_page = [(params[:per_page] || 50).to_i, 200].min

        options = { order: :timestamp, direction: "DESC" }
        options[:where] = {} if params[:status] || params[:scope] || params[:tag]
        options[:where][:status] = params[:status] if params[:status]
        options[:where][:scope] = params[:scope] if params[:scope]
        options[:where][:tag] = params[:tag] if params[:tag]

        begin
          result = server.message_db.messages_with_pagination(page, options.merge(per_page: per_page))
        rescue => e
          return render json: { error: "Message database unavailable: #{e.message}" }, status: :service_unavailable
        end

        render json: {
          data: result[:records].map { |m| serialize_message(m) },
          pagination: {
            page: result[:page],
            per_page: result[:per_page],
            total: result[:total],
            total_pages: result[:total_pages]
          }
        }
      end

      def show
        server = find_server
        begin
          message = server.message_db.message(params[:id].to_i)
        rescue Postal::MessageDB::Message::NotFound
          return render json: { error: "Message not found" }, status: :not_found
        rescue => e
          return render json: { error: "Message database unavailable: #{e.message}" }, status: :service_unavailable
        end
        return render(json: { error: "Message not found" }, status: :not_found) if message.nil?

        render json: { data: serialize_message_detail(message) }
      end

      def retry
        server = find_server
        message = server.message_db.message(params[:id].to_i)
        queued = message.queued_message

        if queued
          queued.retry_now
          render json: { data: { message: "Message queued for retry" } }
        else
          queued = QueuedMessage.create!(
            server_id: server.id,
            message_id: message.id,
            domain: message.recipient_domain,
            batch_key: message.batch_key,
            manual: true
          )
          render json: { data: { message: "Message queued for retry" } }
        end
      rescue Postal::MessageDB::Message::NotFound
        render json: { error: "Message not found" }, status: :not_found
      end

      def deliveries
        server = find_server
        begin
          message = server.message_db.message(params[:id].to_i)
        rescue Postal::MessageDB::Message::NotFound
          return render json: { error: "Message not found" }, status: :not_found
        rescue => e
          return render json: { error: "Message database unavailable: #{e.message}" }, status: :service_unavailable
        end
        return render(json: { error: "Message not found" }, status: :not_found) if message.nil?

        render json: {
          data: message.deliveries.map { |d| serialize_delivery(d) }
        }
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def serialize_message(message)
        {
          id: message.id,
          token: message.token,
          scope: message.scope,
          status: message.status,
          rcpt_to: message.rcpt_to,
          mail_from: message.mail_from,
          subject: message.subject,
          tag: message.tag,
          timestamp: message.timestamp&.to_f,
          message_id: message.message_id
        }
      end

      def serialize_message_detail(message)
        {
          id: message.id,
          token: message.token,
          scope: message.scope,
          status: message.status,
          rcpt_to: message.rcpt_to,
          mail_from: message.mail_from,
          subject: message.subject,
          message_id: message.message_id,
          tag: message.tag,
          size: message.size,
          bounce: message.bounce,
          timestamp: message.timestamp&.to_f,
          last_delivery_attempt: message.last_delivery_attempt&.to_f,
          held: message.held,
          hold_expiry: message.hold_expiry&.to_f,
          received_with_ssl: message.received_with_ssl,
          inspected: message.inspected,
          spam: message.spam,
          spam_score: message.spam_score&.to_f,
          threat: message.threat,
          threat_details: message.threat_details
        }
      end

      def serialize_delivery(delivery)
        {
          id: delivery.id,
          status: delivery.status,
          details: delivery.details,
          output: delivery.output&.strip,
          sent_with_ssl: delivery.sent_with_ssl,
          log_id: delivery.log_id,
          time: delivery.time&.to_f,
          timestamp: delivery.timestamp&.to_f
        }
      end

    end
  end
end
