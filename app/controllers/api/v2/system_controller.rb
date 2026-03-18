# frozen_string_literal: true

module Api
  module V2
    class SystemController < BaseController

      skip_before_action :authenticate

      def health
        render json: { status: "healthy" }
      end

      def version
        render json: { version: Postal.version }
      end

    end
  end
end
