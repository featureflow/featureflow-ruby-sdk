require 'rails/generators'
class FeatureflowGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :api_key, required: true, :desc => "required"

  gem "featureflow"

  desc "Configures the featureflow with your API key"

  def create_initializer_file
    unless /^srv-env-[a-f0-9]{32}$/ =~ api_key
      raise Thor::Error, "Invalid featureflow environment api key #{api_key.inspect}\nYou can find your environment api key on your featureflow dashboard at https://[APP-NAME].featureflow.io/"
    end

    initializer "featureflow.rb" do
      <<-EOF
Featureflow.configure(
  api_key: #{api_key.inspect}
)
      EOF
    end
  end
end