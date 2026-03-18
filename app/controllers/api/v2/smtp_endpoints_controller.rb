# frozen_string_literal: true

module API
  module V2
    class SmtpEndpointsController < BaseController

      def index
        server = find_server
        result = paginate(server.smtp_endpoints.order(:name))
        render json: {
          data: result[:data].map { |e| serialize_smtp_endpoint(e) },
          pagination: result[:pagination]
        }
      end

      def show
        endpoint = find_smtp_endpoint
        render json: { data: serialize_smtp_endpoint(endpoint) }
      end

      def create
        server = find_server
        endpoint = server.smtp_endpoints.new(smtp_endpoint_params)
        endpoint.save!
        render json: { data: serialize_smtp_endpoint(endpoint) }, status: :created
      end

      def update
        endpoint = find_smtp_endpoint
        endpoint.update!(smtp_endpoint_params)
        render json: { data: serialize_smtp_endpoint(endpoint) }
      end

      def destroy
        endpoint = find_smtp_endpoint
        endpoint.destroy!
        head :no_content
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def find_smtp_endpoint
        find_server.smtp_endpoints.find_by!(uuid: params[:uuid])
      end

      def smtp_endpoint_params
        params.permit(:name, :hostname, :port, :ssl_mode)
      end

      def serialize_smtp_endpoint(endpoint)
        {
          uuid: endpoint.uuid,
          name: endpoint.name,
          hostname: endpoint.hostname,
          port: endpoint.port,
          ssl_mode: endpoint.ssl_mode,
          error: endpoint.error,
          disabled_until: endpoint.disabled_until&.iso8601,
          last_used_at: endpoint.last_used_at&.iso8601,
          created_at: endpoint.created_at&.iso8601,
          updated_at: endpoint.updated_at&.iso8601
        }
      end

    end
  end
end
