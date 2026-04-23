# MagistralChat patch: rescue blocks + enterprise fallbacks
# Destino: lib/chatwoot_hub.rb
class ChatwootHub
    DEFAULT_BASE_URL = 'https://hub.2.chatwoot.com'.freeze

    def self.base_url; DEFAULT_BASE_URL; end
    def self.ping_url; "#{base_url}/ping"; end
    def self.registration_url; "#{base_url}/instances"; end
    def self.push_notification_url; "#{base_url}/send_push"; end
    def self.events_url; "#{base_url}/events"; end
    def self.billing_base_url; "#{base_url}/billing"; end

    def self.installation_identifier
          id = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
          id ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
          id
    end

    def self.billing_url
          "#{billing_base_url}?installation_identifier=#{installation_identifier}"
    end

    def self.pricing_plan
          InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'enterprise'
    end

    def self.pricing_plan_quantity
          InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')&.value || 9_999_999
    end

    def self.support_config
          { 'installation_identifier' => installation_identifier,
                  'pricing_plan' => pricing_plan,
                  'pricing_plan_quantity' => pricing_plan_quantity }
    end

    def self.instance_config
          { 'account_id' => 1, 'installation_identifier' => installation_identifier,
                  'pricing_plan' => pricing_plan, 'pricing_plan_quantity' => pricing_plan_quantity }
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] instance_config: #{e.message}"; {}
    end

    def self.instance_metrics
          { 'account_count' => Account.count, 'contact_count' => Contact.count,
                  'conversation_count' => Conversation.count, 'installation_identifier' => installation_identifier }
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] instance_metrics: #{e.message}"; {}
    end

    def self.fetch_count
          InstallationConfig.find_by(name: 'HUB_FETCH_COUNT')&.value.to_i
    end

    def self.sync_with_hub
          return unless ENV.fetch('CHATWOOT_HUB_SYNC', 'true') == 'true'
          res = RestClient.post(ping_url, instance_config.merge(instance_metrics).to_json, { content_type: :json, accept: :json })
          update_installation_configs(JSON.parse(res.body))
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] sync_with_hub: #{e.message}"; nil
    end

    def self.register_instance(name, email)
          return unless ENV.fetch('CHATWOOT_HUB_SYNC', 'true') == 'true'
          RestClient.post(registration_url, instance_config.merge('user_full_name' => name, 'user_email' => email).to_json, { content_type: :json, accept: :json })
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] register_instance: #{e.message}"; nil
    end

    def self.send_push(subscription, message)
          return unless ENV.fetch('CHATWOOT_HUB_SYNC', 'true') == 'true'
          RestClient.post(push_notification_url, { subscription: subscription, message: message }.to_json, { content_type: :json, accept: :json })
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] send_push: #{e.message}"; nil
    end

    def self.send_push_with_response(subscription, message)
          return unless ENV.fetch('CHATWOOT_HUB_SYNC', 'true') == 'true'
          res = RestClient.post(push_notification_url, { subscription: subscription, message: message }.to_json, { content_type: :json, accept: :json })
          JSON.parse(res.body)
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] send_push_with_response: #{e.message}"; nil
    end

    def self.emit_event(event_name, event_data = {})
          return unless ENV.fetch('CHATWOOT_HUB_SYNC', 'true') == 'true'
          RestClient.post(events_url, { installation_identifier: installation_identifier, event_name: event_name, event_data: event_data }.to_json, { content_type: :json, accept: :json })
    rescue StandardError => e
          Rails.logger.error "[ChatwootHub] emit_event: #{e.message}"; nil
    end

    class << self
          private
          def update_installation_configs(data)
                  return unless data.is_a?(Hash)
                  %w[INSTALLATION_PRICING_PLAN INSTALLATION_PRICING_PLAN_QUANTITY].each do |key|
                            next unless data.key?(key)
                            InstallationConfig.find_by(name: key)&.update(value: data[key])
                  end
          rescue StandardError => e
                  Rails.logger.error "[ChatwootHub] update_configs: #{e.message}"
          end
    end
end
