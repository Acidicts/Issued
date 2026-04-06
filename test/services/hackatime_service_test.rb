require "test_helper"

class HackatimeServiceTest < ActiveSupport::TestCase
  test "fetch_stats returns structured project totals and banned state" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "dummy-key"

    payload = {
      "data" => {
        "projects" => [
          { "name" => "Project A", "total_seconds" => 3600 },
          { "name" => "Project B", "total_seconds" => 1800 }
        ],
        "trust_factor" => { "trust_value" => 0 }
      }
    }

    singleton_class = HackatimeService.singleton_class
    singleton_class.class_eval do
      alias_method :original_get_json, :get_json
      define_method(:get_json) { |_path, _params = {}| payload }
    end

    result = HackatimeService.fetch_stats("U123", start_date: "2025-01-01")

    assert_equal({ "Project A" => 3600, "Project B" => 1800 }, result[:projects])
    assert_equal false, result[:banned]
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
    singleton_class.class_eval do
      define_method(:get_json, instance_method(:original_get_json))
      remove_method :original_get_json
    end
  end

  test "available? is false without api key" do
    old_api_key = ENV.delete("HACKATIME_API_KEY")

    assert_not HackatimeService.available?
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key if old_api_key
  end
end
