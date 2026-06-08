RSpec.configure do |config|
  config.around(:each, :with_env) do |example|
    env_overrides = example.metadata[:with_env]

    original_env = ENV.slice(*env_overrides.keys)
    begin
      env_overrides.each_pair do |key, value|
        ENV[key] = value
        ENV.delete(key) if value.nil?
      end
      example.run
    ensure
      env_overrides.keys.each do |key|
        ENV[key] = original_env[key]
        ENV.delete(key) if original_env[key].nil?
      end
    end
  end
end
