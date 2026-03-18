# frozen_string_literal: true

module Api
  module V2
    class SuppressionsController < BaseController

      def index
        server = find_server
        page = (params[:page] || 1).to_i
        page = 1 if page < 1
        result = server.message_db.suppression_list.all_with_pagination(page)
        render json: {
          data: result[:records].map { |s| serialize_suppression(s) },
          pagination: {
            page: result[:page],
            per_page: result[:per_page],
            total: result[:total],
            total_pages: result[:total_pages]
          }
        }
      end

      def create
        server = find_server
        if params[:address].blank?
          render json: { error: "address is required" }, status: :unprocessable_entity
          return
        end
        unless params[:address].to_s.include?("@")
          return render json: { error: "Invalid email address" }, status: :bad_request
        end
        type = params[:type] || "HardFail"
        server.message_db.suppression_list.add(type, params[:address], reason: params[:reason])
        render json: { data: { address: params[:address], type: type } }, status: :created
      end

      def bulk
        server = find_server
        addresses = params[:addresses]
        unless addresses.is_a?(Array) && addresses.any?
          render json: { error: "addresses array is required" }, status: :unprocessable_entity
          return
        end
        addresses = addresses.select { |a| a.to_s.include?("@") }
        return render(json: { error: "No valid addresses" }, status: :bad_request) if addresses.empty?

        type = params[:type] || "HardFail"
        addresses.each do |address|
          server.message_db.suppression_list.add(type, address, reason: params[:reason])
        end
        render json: { data: { count: addresses.size } }, status: :created
      end

      def destroy
        server = find_server
        email = params[:address]
        return render(json: { error: "address required" }, status: :bad_request) if email.blank?
        type = params[:type] || "HardFail"
        removed = server.message_db.suppression_list.remove(type, email)
        if removed
          head :no_content
        else
          render json: { error: "Suppression not found" }, status: :not_found
        end
      end

      private

      def find_server
        @server.organization.servers.where(deleted_at: nil).find_by!(uuid: params[:server_uuid])
      end

      def serialize_suppression(suppression)
        {
          id: suppression["id"],
          type: suppression["type"],
          address: suppression["address"],
          reason: suppression["reason"],
          timestamp: suppression["timestamp"],
          keep_until: suppression["keep_until"]
        }
      end

    end
  end
end
