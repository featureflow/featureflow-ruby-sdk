class Featureflow::RequestParser
  def initialize(env)
    @env = env
  end

  def parse
    request = ActionDispatch::Request.new(@env)

    {
      'featureflow.ip' => request.remote_ip,
      'featureflow.url' => request.original_url
    }
  end
end