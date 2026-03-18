# frozen_string_literal: true

module Api
  module V2
    class RoutesController < BaseController

      def index
        server = find_server
        result = paginate(server.routes.includes(:domain).order(:name))
        render json: {
          data: result[:data].map { |r| serialize_route(r) },
          pagination: result[:pagination]
        }
      end

      def show
        route = find_route
        render json: { data: serialize_route(route) }
      end

      def create
        server = find_server
        route = server.routes.new(route_params)
        route._endpoint = params[:endpoint] if params[:endpoint]
        route.save!
        render json: { data: serialize_route(route) }, status: :created
      end

      def update
        route = find_route
        route.assign_attributes(route_params)
        route._endpoint = params[:endpoint] if params[:endpoint]
        route.save!
        render json: { data: serialize_route(route) }
      end

      def destroy
        route = find_route
        route.destroy!
        head :no_content
      end

      def add_endpoint
        route = find_route
        endpoint_ref = params[:endpoint]
        return render(json: { error: "endpoint parameter required" }, status: :unprocessable_entity) unless endpoint_ref

        additional = route.additional_route_endpoints.build(_endpoint: endpoint_ref)
        additional.save!
        render json: {
          data: {
            id: additional.id,
            endpoint: additional._endpoint,
            endpoint_type: additional.endpoint_type,
            endpoint_id: additional.endpoint_id
          }
        }, status: :created
      end

      def remove_endpoint
        route = find_route
        additional = route.additional_route_endpoints.find(params[:additional_id])
        additional.destroy!
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Endpoint not found" }, status: :not_found
      end

      def additional_endpoints
        route = find_route
        render json: {
          data: route.additional_route_endpoints.map { |ae|
            {
              id: ae.id,
              endpoint: ae._endpoint,
              endpoint_type: ae.endpoint_type,
              endpoint_id: ae.endpoint_id,
              created_at: ae.created_at&.iso8601
            }
          }
        }
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def find_route
        find_server.routes.find_by!(uuid: params[:uuid])
      end

      def route_params
        params.permit(:name, :domain_id, :spam_mode)
      end

      def serialize_route(route)
        {
          uuid: route.uuid,
          name: route.name,
          domain: route.domain&.name,
          domain_id: route.domain_id,
          endpoint: route._endpoint,
          endpoint_type: route.endpoint_type,
          mode: route.mode,
          spam_mode: route.spam_mode,
          token: route.token,
          forward_address: route.forward_address,
          description: route.description,
          created_at: route.created_at&.iso8601,
          updated_at: route.updated_at&.iso8601
        }
      end

    end
  end
end
