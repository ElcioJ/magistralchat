# MagistralChat Enterprise Setup
# This script ensures enterprise configs are set on every deploy.
# Run via: bundle exec rails runner db/seeders/enterprise_setup.rb
# Or call from db/seeds.rb: load Rails.root.join('db/seeders/enterprise_setup.rb')
#
# It is idempotent — safe to run multiple times.
# DASHBOARD_SCRIPTS is only created if it does not exist (preserves UI edits).

puts "[MagistralChat] Running enterprise_setup..."

# ─── Configs always enforced (overwrite on every deploy) ──────────────────────
ENTERPRISE_CONFIGS = {
    'INSTALLATION_NAME'               => 'MagistralChat',
    'INSTALLATION_PRICING_PLAN'       => 'enterprise',
    'INSTALLATION_PRICING_PLAN_QUANTITY' => '9999999',
    'BRAND_NAME'                      => 'MagistralChat',
    'BRAND_URL'                       => ENV.fetch('FRONTEND_URL', 'https://mc1.multiate.com.br'),
    'WIDGET_BRAND_URL'                => ENV.fetch('FRONTEND_URL', 'https://mc1.multiate.com.br')
}.freeze

ENTERPRISE_CONFIGS.each do |key, value|
    config = InstallationConfig.find_or_initialize_by(name: key)
    if config.new_record? || config.value.to_s != value.to_s
          config.value = value
          config.save!
          puts "[MagistralChat] Set #{key} = #{value}"
    else
          puts "[MagistralChat] #{key} already correct (#{value})"
    end
end

# ─── Configs created once — never overwritten (editable via Super Admin UI) ───
OPTIONAL_CONFIGS = {
    'DASHBOARD_SCRIPTS' => ''
}.freeze

OPTIONAL_CONFIGS.each do |key, default_value|
    config = InstallationConfig.find_by(name: key)
    if config.nil?
          InstallationConfig.create!(name: key, value: default_value)
          puts "[MagistralChat] Created #{key} (default empty — edit via Super Admin)"
    else
          puts "[MagistralChat] #{key} already exists — skipping (UI value preserved)"
    end
end

puts "[MagistralChat] enterprise_setup complete."
puts "[MagistralChat] enterprise? => #{ChatwootApp.enterprise?}"
puts "[MagistralChat] max_limit   => #{ChatwootApp.max_limit}"
