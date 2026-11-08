module Api
  module V1
    class BacktestsController < BaseController
      DEFAULT_INITIAL_AMOUNT = 1_000_000
      INITIAL_AMOUNT_RANGE = (1..1_000_000_000)
      WITHDRAWAL_RATE_RANGE = (0.5..20.0)
      FEE_RANGE = (0.0..3.0)

      before_action :parse_inputs
      before_action :load_calculator

      def index
        results = @calculator.backtest_all(**backtest_options)

        render_cached(
          inputs: inputs_payload,
          summary: @calculator.summary_stats(results, horizon: @horizon),
          results: results.map { |result| result_payload(result) },
          meta: meta_payload("#{request.base_url}/?#{ui_query}")
        )
      end

      def show
        starting_year = Integer(params[:starting_year].to_s, 10, exception: false)
        available = @calculator.available_years.select { |year| year >= (@scenario.first_year || year) }
        return render_error("No data for starting_year #{params[:starting_year]}", :not_found) unless available.include?(starting_year)

        options = backtest_options.merge(starting_year: starting_year)
        result = @calculator.backtest(**options)
        series = @calculator.series(**options)
        year_query = @scenario == Scenario.default ? ui_query : "#{ui_query}&scenario=#{@scenario.key}"

        render_cached(
          inputs: inputs_payload,
          result: result_payload(result),
          series: series,
          meta: meta_payload("#{request.base_url}/year_detail/#{starting_year}?#{year_query}")
        )
      end

      private

      def parse_inputs
        @withdrawal_rate = params.key?(:withdrawal_rate) ? parse_float("withdrawal_rate", params[:withdrawal_rate]) : 4.0
        @fee = params.key?(:fee) ? parse_float("fee", params[:fee]) : 0.0
        @horizon = params.key?(:horizon) ? parse_integer("horizon", params[:horizon]) : 30
        @scenario = params.key?(:scenario) ? Scenario.from_param(params[:scenario]) : Scenario.default

        raise InvalidRequest, "scenario must be one of: #{Scenario::ALL.map(&:key).join(', ')}" unless @scenario
        raise InvalidRequest, "withdrawal_rate must be between #{WITHDRAWAL_RATE_RANGE.min} and #{WITHDRAWAL_RATE_RANGE.max}" unless WITHDRAWAL_RATE_RANGE.cover?(@withdrawal_rate)
        raise InvalidRequest, "fee must be between #{FEE_RANGE.min} and #{FEE_RANGE.max}" unless FEE_RANGE.cover?(@fee)
        raise InvalidRequest, "horizon must be one of: #{Calculator::MILESTONES.join(', ')}" unless Calculator::MILESTONES.include?(@horizon)

        if params.key?(:annual_spending)
          spending = parse_integer("annual_spending", params[:annual_spending])
          raise InvalidRequest, "annual_spending must be greater than 0" unless spending.positive?

          @annual_spending = spending
          @initial_amount = Calculator.required_portfolio(annual_spending: spending, withdrawal_rate: @withdrawal_rate)
        else
          @initial_amount = params.key?(:initial_amount) ? parse_integer("initial_amount", params[:initial_amount]) : DEFAULT_INITIAL_AMOUNT
          @annual_spending = (@initial_amount * @withdrawal_rate / 100).round
        end
        unless INITIAL_AMOUNT_RANGE.cover?(@initial_amount)
          raise InvalidRequest, "initial_amount must be between #{INITIAL_AMOUNT_RANGE.min} and #{INITIAL_AMOUNT_RANGE.max}"
        end
      end

      def load_calculator
        @calculator = Calculator.new
      end

      def backtest_options
        { initial_amount: @initial_amount, withdrawal_rate: @withdrawal_rate, scenario: @scenario, fee: @fee }
      end

      def inputs_payload
        {
          initial_amount: @initial_amount,
          annual_spending: @annual_spending,
          withdrawal_rate: @withdrawal_rate,
          fee: @fee,
          scenario: @scenario.key,
          scenario_label: @scenario.label,
          horizon: @horizon
        }
      end

      def result_payload(result)
        result.slice(:starting_year, :depleted_at, :final_portfolio, :milestones)
      end

      def ui_query
        URI.encode_www_form(initial_amount: @initial_amount, withdrawal_rate: @withdrawal_rate, fee: @fee, horizon: @horizon)
      end

      def meta_payload(ui_url)
        years = @calculator.available_years
        {
          data_range: { first_year: years.first, last_year: years.last },
          methodology_url: meta_links[:methodology_url],
          data_url: "#{request.base_url}/api/v1/data",
          source_url: meta_links[:source_url],
          license: meta_links[:license],
          ui_url: ui_url
        }
      end
    end
  end
end
