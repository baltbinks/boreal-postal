# frozen_string_literal: true

module API
  module V2
    class IPAddressesController < BaseController

      def index
        pool = @server.organization.ip_pools.find_by!(uuid: params[:ip_pool_uuid])
        result = paginate(pool.ip_addresses.order_by_priority)
        render json: {
          data: result[:data].map { |ip| serialize_ip_address(ip) },
          pagination: result[:pagination]
        }
      end

      private

      def serialize_ip_address(ip)
        {
          id: ip.id,
          hostname: ip.hostname,
          ipv4: ip.ipv4,
          ipv6: ip.ipv6,
          priority: ip.priority,
          created_at: ip.created_at&.iso8601
        }
      end

    end
  end
end
