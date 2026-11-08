class AgentClassifier
  AGENT_FETCH = %w[
    ChatGPT-User OAI-SearchBot Claude-User Claude-SearchBot Perplexity-User PerplexityBot DuckAssistBot
    Gemini-Deep-Research Google-CloudVertexBot MistralAI-User YouBot Devin Cursor Codex claude-code
  ].freeze

  TRAINING_CRAWLER = %w[
    GPTBot ClaudeBot anthropic-ai Google-Extended CCBot Bytespider meta-externalagent Applebot-Extended
    Amazonbot cohere-ai Diffbot PetalBot
  ].freeze

  AGENT_FETCH_PATTERN = Regexp.union(AGENT_FETCH.map { |name| Regexp.new(Regexp.escape(name), Regexp::IGNORECASE) })
  TRAINING_CRAWLER_PATTERN = Regexp.union(TRAINING_CRAWLER.map { |name| Regexp.new(Regexp.escape(name), Regexp::IGNORECASE) })
  AGENT_PATHS = %w[/llms.txt /methodology.md].freeze

  def self.classify(user_agent:, path:)
    user_agent = user_agent.to_s
    path = path.to_s

    return "agent_fetch" if user_agent.match?(AGENT_FETCH_PATTERN)
    return "training_crawler" if user_agent.match?(TRAINING_CRAWLER_PATTERN)
    return "browser" if user_agent.include?("Mozilla/")
    return "api_client" if path.start_with?("/api/") || AGENT_PATHS.include?(path)

    "other"
  end
end
