# frozen_string_literal: true

module Api
  module V2
    class TrackDomainsController < BaseController

      def index
        server = find_server
        result = paginate(server.track_domains.includes(:domain).order(:name))
        render json: {
          data: result[:data].map { |td| serialize_track_domain(td) },
          pagination: result[:pagination]
        }
      end

      def show
        track_domain = find_track_domain
        render json: { data: serialize_track_domain(track_domain) }
      end

      def create
        server = find_server
        track_domain = server.track_domains.new(track_domain_params)
        track_domain.save!
        render json: { data: serialize_track_domain(track_domain) }, status: :created
      end

      def update
        track_domain = find_track_domain
        track_domain.update!(track_domain_params)
        render json: { data: serialize_track_domain(track_domain) }
      end

      def destroy
        track_domain = find_track_domain
        track_domain.destroy!
        head :no_content
      end

      private

      def find_server
        @server.organization.servers.find_by!(uuid: params[:server_uuid])
      end

      def find_track_domain
        find_server.track_domains.find_by!(uuid: params[:uuid])
      end

      def track_domain_params
        params.permit(:name, :domain_id, :ssl_enabled, :track_clicks,
                       :track_loads, :excluded_click_domains)
      end

      def serialize_track_domain(track_domain)
        {
          uuid: track_domain.uuid,
          name: track_domain.name,
          domain: track_domain.domain&.name,
          domain_id: track_domain.domain_id,
          full_name: track_domain.full_name,
          ssl_enabled: track_domain.ssl_enabled,
          track_clicks: track_domain.track_clicks,
          track_loads: track_domain.track_loads,
          excluded_click_domains: track_domain.excluded_click_domains,
          dns_status: track_domain.dns_status,
          dns_error: track_domain.dns_error,
          dns_checked_at: track_domain.dns_checked_at&.iso8601,
          created_at: track_domain.created_at&.iso8601,
          updated_at: track_domain.updated_at&.iso8601
        }
      end

    end
  end
end
