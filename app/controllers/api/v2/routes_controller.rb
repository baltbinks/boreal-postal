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

      private

      def find_server
        @server.organization.servers.find_by!(uuid: params[:server_uuid])
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
