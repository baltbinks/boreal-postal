# frozen_string_literal: true

module Api
  module V2
    class BaseController < ActionController::API

      before_action :authenticate
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

      private

      def authenticate
        key = request.headers["X-Server-API-Key"]
        if key.blank?
          render json: { error: "Missing API key" }, status: :unauthorized
          return
        end

        @current_credential = Credential.where(type: "API", key: key).first
        if @current_credential.nil?
          render json: { error: "Invalid API key" }, status: :unauthorized
          return
        end

        @server = @current_credential.server
        if @server.suspended?
          render json: { error: "Server is suspended" }, status: :forbidden
          return
        end

        @current_credential.use
      end

      def paginate(scope)
        page = (params[:page] || 1).to_i
        per_page = [(params[:per_page] || 50).to_i, 200].min
        per_page = 1 if per_page < 1
        page = 1 if page < 1
        offset = (page - 1) * per_page

        total = scope.count
        records = scope.offset(offset).limit(per_page)

        total_pages = (total / per_page.to_f).ceil
        total_pages = 1 if total_pages < 1

        {
          data: records,
          pagination: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: total_pages
          }
        }
      end

      def not_found
        render json: { error: "Resource not found" }, status: :not_found
      end

      def unprocessable(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

    end
  end
end
