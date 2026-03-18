# frozen_string_literal: true

module Api
  module V2
    class DomainsController < BaseController

      def index
        server = find_server
        result = paginate(server.domains.order(:name))
        render json: {
          data: result[:data].map { |d| serialize_domain(d) },
          pagination: result[:pagination]
        }
      end

      def show
        domain = find_domain
        render json: { data: serialize_domain(domain) }
      end

      def create
        server = find_server
        domain = server.domains.new(domain_params)
        domain.owner = server
        domain.save!
        render json: { data: serialize_domain(domain) }, status: :created
      end

      def update
        domain = find_domain
        domain.update!(domain_params)
        render json: { data: serialize_domain(domain) }
      end

      def destroy
        domain = find_domain
        domain.destroy!
        head :no_content
      end

      def check_dns
        domain = find_domain
        dns_ok = domain.check_dns
        render json: {
          data: {
            dns_ok: dns_ok,
            spf_status: domain.spf_status,
            spf_error: domain.spf_error,
            dkim_status: domain.dkim_status,
            dkim_error: domain.dkim_error,
            mx_status: domain.mx_status,
            mx_error: domain.mx_error,
            return_path_status: domain.return_path_status,
            return_path_error: domain.return_path_error,
            dns_checked_at: domain.dns_checked_at&.iso8601
          }
        }
      end

      def dns_records
        domain = find_domain

        records = []

        records << {
          type: "TXT",
          name: domain.name,
          content: domain.spf_record,
          purpose: "SPF"
        }

        if domain.dkim_record_name && domain.dkim_record
          records << {
            type: "TXT",
            name: "#{domain.dkim_record_name}.#{domain.name}",
            content: domain.dkim_record,
            purpose: "DKIM"
          }
        end

        records << {
          type: "CNAME",
          name: domain.return_path_domain,
          content: Postal::Config.dns.return_path_domain,
          purpose: "Return Path"
        }

        Postal::Config.dns.mx_records.each do |mx_record|
          records << {
            type: "MX",
            name: domain.name,
            content: mx_record,
            priority: 10,
            purpose: "MX"
          }
        end

        if domain.verification_token.present?
          records << {
            type: "TXT",
            name: domain.name,
            content: domain.dns_verification_string,
            purpose: "Verification"
          }
        end

        render json: { data: records }
      end

      private

      def find_server
        @server.organization.servers.find_by!(uuid: params[:server_uuid])
      end

      def find_domain
        find_server.domains.find_by!(uuid: params[:uuid])
      end

      def domain_params
        params.permit(:name, :verification_method, :outgoing, :incoming, :use_for_any)
      end

      def serialize_domain(domain)
        {
          uuid: domain.uuid,
          name: domain.name,
          verification_method: domain.verification_method,
          verification_token: domain.verification_token,
          verified_at: domain.verified_at&.iso8601,
          outgoing: domain.outgoing,
          incoming: domain.incoming,
          use_for_any: domain.use_for_any,
          dkim_identifier: domain.dkim_identifier,
          spf_status: domain.spf_status,
          spf_error: domain.spf_error,
          dkim_status: domain.dkim_status,
          dkim_error: domain.dkim_error,
          mx_status: domain.mx_status,
          mx_error: domain.mx_error,
          return_path_status: domain.return_path_status,
          return_path_error: domain.return_path_error,
          dns_checked_at: domain.dns_checked_at&.iso8601,
          created_at: domain.created_at&.iso8601,
          updated_at: domain.updated_at&.iso8601
        }
      end

    end
  end
end
