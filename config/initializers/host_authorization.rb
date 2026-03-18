# frozen_string_literal: true

# Allow all hosts for API access. Postal instances are managed
# via API and accessed from various hostnames/IPs.
Rails.application.config.hosts.clear
