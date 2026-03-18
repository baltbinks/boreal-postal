# frozen_string_literal: true

module Api
  module V2
    class CredentialsController < BaseController

      def index
        server = find_server
        result = paginate(server.credentials.order(:name))
        render json: {
          data: result[:data].map { |c| serialize_credential(c) },
          pagination: result[:pagination]
        }
      end

      def show
        credential = find_credential
        render json: { data: serialize_credential(credential) }
      end

      def create
        server = find_server
        credential = server.credentials.new(credential_params)
        credential.save!
        render json: { data: serialize_credential(credential) }, status: :created
      end

      def update
        credential = find_credential
        credential.update!(credential_params)
        render json: { data: serialize_credential(credential) }
      end

      def destroy
        credential = find_credential
        credential.destroy!
        head :no_content
      end

      private

      def find_server
        @server.organization.servers.find_by!(uuid: params[:server_uuid])
      end

      def find_credential
        find_server.credentials.find_by!(uuid: params[:uuid])
      end

      def credential_params
        params.permit(:name, :type, :key, :hold)
      end

      def serialize_credential(credential)
        {
          uuid: credential.uuid,
          name: credential.name,
          type: credential.type,
          key: credential.key,
          hold: credential.hold,
          last_used_at: credential.last_used_at&.iso8601,
          created_at: credential.created_at&.iso8601,
          updated_at: credential.updated_at&.iso8601
        }
      end

    end
  end
end
