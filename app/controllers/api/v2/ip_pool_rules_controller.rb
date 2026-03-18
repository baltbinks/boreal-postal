# frozen_string_literal: true

module API
  module V2
    class IPPoolRulesController < BaseController

      def index
        pool = find_pool
        result = paginate(pool.ip_pool_rules.order(:created_at))
        render json: {
          data: result[:data].map { |r| serialize_rule(r) },
          pagination: result[:pagination]
        }
      end

      def show
        rule = find_rule
        render json: { data: serialize_rule(rule) }
      end

      def create
        pool = find_pool
        rule = pool.ip_pool_rules.new(rule_params)
        rule.owner = @server.organization
        rule.save!
        render json: { data: serialize_rule(rule) }, status: :created
      end

      def update
        rule = find_rule
        rule.update!(rule_params)
        render json: { data: serialize_rule(rule) }
      end

      def destroy
        rule = find_rule
        rule.destroy!
        head :no_content
      end

      private

      def find_pool
        @server.organization.ip_pools.find_by!(uuid: params[:ip_pool_uuid])
      end

      def find_rule
        find_pool.ip_pool_rules.find_by!(uuid: params[:uuid])
      end

      def rule_params
        params.permit(:from_text, :to_text)
      end

      def serialize_rule(rule)
        {
          uuid: rule.uuid,
          owner_type: rule.owner_type,
          owner_id: rule.owner_id,
          ip_pool_id: rule.ip_pool_id,
          from: rule.from,
          to: rule.to,
          created_at: rule.created_at&.iso8601,
          updated_at: rule.updated_at&.iso8601
        }
      end

    end
  end
end
