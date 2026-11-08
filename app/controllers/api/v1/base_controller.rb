module Api
  module V1
    class BaseController < ActionController::API
      include AgentTracking

      METHODOLOGY_PATH = "/methodology.md".freeze
      SOURCE_URL = "https://github.com/joparisot/4percentcalc".freeze
      LICENSE = "MIT. Data: Robert Shiller (Yale) and DQYDJ; see /methodology.md.".freeze

      class InvalidRequest < StandardError; end

      rescue_from InvalidRequest do |error|
        render_error(error.message, :bad_request)
      end

      private

      def render_error(message, status)
        response.headers["Cache-Control"] = "no-store"
        render json: { error: message }, status: status
      end

      def render_cached(payload)
        expires_in 1.day, public: true
        render json: payload if stale?(etag: payload, public: true)
      end

      def meta_links
        {
          methodology_url: "#{request.base_url}#{METHODOLOGY_PATH}",
          source_url: SOURCE_URL,
          license: LICENSE
        }
      end

      def parse_integer(name, value)
        Integer(value.to_s, 10, exception: false) || raise(InvalidRequest, "#{name} must be an integer")
      end

      def parse_float(name, value)
        Float(value.to_s, exception: false) || raise(InvalidRequest, "#{name} must be a number")
      end
    end
  end
end
