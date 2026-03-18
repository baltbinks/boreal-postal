# frozen_string_literal: true

module Api
  module V2
    class IpPoolsController < BaseController

      def index
        pools = @server.organization.ip_pools.includes(:ip_addresses)
        result = paginate(pools.order(:name))
        render json: {
          data: result[:data].map { |p| serialize_ip_pool(p) },
          pagination: result[:pagination]
        }
      end

      def show
        pool = @server.organization.ip_pools.includes(:ip_addresses).find_by!(uuid: params[:uuid])
        render json: { data: serialize_ip_pool(pool) }
      end

      private

      def serialize_ip_pool(pool)
        {
          uuid: pool.uuid,
          name: pool.name,
          default: pool.default,
          ip_addresses_count: pool.ip_addresses.length,
          created_at: pool.created_at&.iso8601,
          updated_at: pool.updated_at&.iso8601
        }
      end

    end
  end
end
