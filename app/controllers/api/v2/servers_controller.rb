# frozen_string_literal: true

module Api
  module V2
    class ServersController < BaseController

      def index
        servers = @server.organization.servers
        result = paginate(servers.order(:name))
        render json: {
          data: result[:data].map { |s| serialize_server(s) },
          pagination: result[:pagination]
        }
      end

      def show
        server = find_server
        render json: { data: serialize_server(server) }
      end

      def create
        server = @server.organization.servers.new(server_params)
        server.save!
        render json: { data: serialize_server(server) }, status: :created
      end

      def update
        server = find_server
        server.update!(server_params)
        render json: { data: serialize_server(server) }
      end

      def suspend
        server = find_server
        reason = params[:reason] || "Suspended via API"
        server.suspend(reason)
        render json: { data: serialize_server(server) }
      end

      def unsuspend
        server = find_server
        server.unsuspend
        render json: { data: serialize_server(server) }
      end

      def queue
        server = find_server
        queued = server.queued_messages.ready.order(created_at: :desc)
        result = paginate(queued)
        render json: {
          data: result[:data].map { |qm| serialize_queued_message(qm) },
          pagination: result[:pagination]
        }
      end

      def stats
        server = find_server
        throughput = server.throughput_stats
        render json: {
          data: {
            incoming: throughput[:incoming],
            outgoing: throughput[:outgoing],
            outgoing_usage: throughput[:outgoing_usage],
            bounce_rate: server.bounce_rate,
            held_messages: server.held_messages,
            queue_size: server.queue_size,
            send_limit: server.send_limit
          }
        }
      end

      def send_message
        attributes = {}
        attributes[:to] = params[:to]
        attributes[:cc] = params[:cc]
        attributes[:bcc] = params[:bcc]
        attributes[:from] = params[:from]
        attributes[:sender] = params[:sender]
        attributes[:subject] = params[:subject]
        attributes[:reply_to] = params[:reply_to]
        attributes[:plain_body] = params[:plain_body]
        attributes[:html_body] = params[:html_body]
        attributes[:bounce] = params[:bounce] ? true : false
        attributes[:tag] = params[:tag]
        attributes[:custom_headers] = params[:headers] if params[:headers]
        attributes[:attachments] = []

        (params[:attachments] || []).each do |attachment|
          next unless attachment.is_a?(ActionController::Parameters) || attachment.is_a?(Hash)

          attributes[:attachments] << {
            name: attachment[:name],
            content_type: attachment[:content_type],
            data: attachment[:data],
            base64: true
          }
        end

        message = OutgoingMessagePrototype.new(@server, request.ip, "api", attributes)
        message.credential = @current_credential
        if message.valid?
          result = message.create_messages
          render json: { data: { message_id: message.message_id, messages: result } }, status: :created
        else
          render json: { error: message.errors.first }, status: :unprocessable_entity
        end
      end

      def send_raw
        unless params[:rcpt_to].is_a?(Array)
          render json: { error: "rcpt_to is required and must be an array" }, status: :unprocessable_entity
          return
        end

        if params[:mail_from].blank?
          render json: { error: "mail_from is required" }, status: :unprocessable_entity
          return
        end

        if params[:data].blank?
          render json: { error: "data is required" }, status: :unprocessable_entity
          return
        end

        raw_message = Base64.decode64(params[:data])
        mail = Mail.new(raw_message.split("\r\n\r\n", 2).first)
        from_headers = { "from" => mail.from, "sender" => mail.sender }
        authenticated_domain = @server.find_authenticated_domain_from_headers(from_headers)

        if authenticated_domain.nil?
          render json: { error: "From address is not authenticated for this server" }, status: :unprocessable_entity
          return
        end

        result = { message_id: nil, messages: {} }
        params[:rcpt_to].uniq.each do |rcpt_to|
          msg = @server.message_db.new_message
          msg.rcpt_to = rcpt_to
          msg.mail_from = params[:mail_from]
          msg.raw_message = raw_message
          msg.received_with_ssl = true
          msg.scope = "outgoing"
          msg.domain_id = authenticated_domain.id
          msg.credential_id = @current_credential.id
          msg.bounce = params[:bounce] ? true : false
          msg.save
          result[:message_id] = msg.message_id if result[:message_id].nil?
          result[:messages][rcpt_to] = { id: msg.id, token: msg.token }
        end

        render json: { data: result }, status: :created
      end

      private

      def find_server
        @server.organization.servers.find_by!(uuid: params[:uuid])
      end

      def server_params
        params.permit(:name, :mode, :ip_pool_id, :send_limit, :message_retention_days,
                       :raw_message_retention_days, :raw_message_retention_size,
                       :outbound_spam_threshold, :spam_threshold, :spam_failure_threshold,
                       :postmaster_address, :domains_not_to_click_track,
                       :log_smtp_data, :allow_sender, :privacy_mode)
      end

      def serialize_server(server)
        {
          uuid: server.uuid,
          name: server.name,
          permalink: server.permalink,
          mode: server.mode,
          status: server.status,
          ip_pool_id: server.ip_pool_id,
          send_limit: server.send_limit,
          message_retention_days: server.message_retention_days,
          raw_message_retention_days: server.raw_message_retention_days,
          raw_message_retention_size: server.raw_message_retention_size,
          outbound_spam_threshold: server.outbound_spam_threshold&.to_f,
          spam_threshold: server.spam_threshold&.to_f,
          spam_failure_threshold: server.spam_failure_threshold&.to_f,
          postmaster_address: server.postmaster_address,
          domains_not_to_click_track: server.domains_not_to_click_track,
          allow_sender: server.allow_sender,
          log_smtp_data: server.log_smtp_data,
          privacy_mode: server.privacy_mode,
          suspended_at: server.suspended_at&.iso8601,
          suspension_reason: server.suspension_reason,
          created_at: server.created_at&.iso8601,
          updated_at: server.updated_at&.iso8601
        }
      end

      def serialize_queued_message(qm)
        {
          id: qm.id,
          message_id: qm.message_id,
          domain: qm.domain,
          attempts: qm.attempts,
          retry_after: qm.retry_after&.iso8601,
          created_at: qm.created_at&.iso8601
        }
      end

    end
  end
end
