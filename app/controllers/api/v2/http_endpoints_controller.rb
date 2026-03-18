# frozen_string_literal: true

module API
  module V2
    class HttpEndpointsController < BaseController

      def index
        server = find_server
        result = paginate(server.http_endpoints.order(:name))
        render json: {
          data: result[:data].map { |e| serialize_http_endpoint(e) },
          pagination: result[:pagination]
        }
      end

      def show
        endpoint = find_http_endpoint
        render json: { data: serialize_http_endpoint(endpoint) }
      end

      def create
        server = find_server
        endpoint = server.http_endpoints.new(http_endpoint_params)
        endpoint.save!
        render json: { data: serialize_http_endpoint(endpoint) }, status: :created
      end

      def update
        endpoint = find_http_endpoint
        endpoint.update!(http_endpoint_params)
        render json: { data: serialize_http_endpoint(endpoint) }
      end

      def destroy
        endpoint = find_http_endpoint
        endpoint.destroy!
        head :no_content
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def find_http_endpoint
        find_server.http_endpoints.find_by!(uuid: params[:uuid])
      end

      def http_endpoint_params
        params.permit(:name, :url, :encoding, :format, :strip_replies,
                       :timeout, :include_attachments)
      end

      def serialize_http_endpoint(endpoint)
        {
          uuid: endpoint.uuid,
          name: endpoint.name,
          url: endpoint.url,
          encoding: endpoint.encoding,
          format: endpoint.format,
          strip_replies: endpoint.strip_replies,
          timeout: endpoint.timeout,
          include_attachments: endpoint.include_attachments,
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
