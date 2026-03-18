# frozen_string_literal: true

module Api
  module V2
    class SystemController < BaseController

      skip_before_action :authenticate, only: [:health, :version, :provision_ready]

      def health
        render json: { status: "healthy" }
      end

      def version
        render json: { version: Postal.version }
      end

      def stats
        stat = Statistic.global
        render json: {
          data: {
            total_messages: stat.total_messages,
            total_incoming: stat.total_incoming,
            total_outgoing: stat.total_outgoing
          }
        }
      end

      def provision_ready
        token = request.headers["X-Provision-Token"]
        expected = ENV["PROVISION_SHARED_SECRET"]
        if expected.blank? || token != expected
          render json: { error: "Invalid provision token" }, status: :unauthorized
          return
        end

        server = Server.order(:id).last
        unless server
          render json: { error: "No server available" }, status: :not_found
          return
        end

        credential = server.credentials.where(type: "API").first
        render json: {
          data: {
            server_uuid: server.uuid,
            credential_key: credential&.key
          }
        }
      end

    end
  end
end
