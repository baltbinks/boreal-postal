# frozen_string_literal: true

module Api
  module V2
    class AddressEndpointsController < BaseController

      def index
        server = find_server
        result = paginate(server.address_endpoints.order(:address))
        render json: {
          data: result[:data].map { |e| serialize_address_endpoint(e) },
          pagination: result[:pagination]
        }
      end

      def show
        endpoint = find_address_endpoint
        render json: { data: serialize_address_endpoint(endpoint) }
      end

      def create
        server = find_server
        endpoint = server.address_endpoints.new(address_endpoint_params)
        endpoint.save!
        render json: { data: serialize_address_endpoint(endpoint) }, status: :created
      end

      def update
        endpoint = find_address_endpoint
        endpoint.update!(address_endpoint_params)
        render json: { data: serialize_address_endpoint(endpoint) }
      end

      def destroy
        endpoint = find_address_endpoint
        endpoint.destroy!
        head :no_content
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def find_address_endpoint
        find_server.address_endpoints.find_by!(uuid: params[:uuid])
      end

      def address_endpoint_params
        params.permit(:address)
      end

      def serialize_address_endpoint(endpoint)
        {
          uuid: endpoint.uuid,
          address: endpoint.address,
          last_used_at: endpoint.last_used_at&.iso8601,
          created_at: endpoint.created_at&.iso8601,
          updated_at: endpoint.updated_at&.iso8601
        }
      end

    end
  end
end
