module AgentTracking
  extend ActiveSupport::Concern

  private

  def append_info_to_payload(payload)
    super
    user_agent = request.user_agent.to_s
    payload[:user_agent] = user_agent
    payload[:agent_class] = AgentClassifier.classify(user_agent: user_agent, path: request.path)
    payload[:src] = params[:src]
    payload[:ip] = request.remote_ip
  end
end
