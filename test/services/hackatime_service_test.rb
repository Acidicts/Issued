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

  test "available? is true with api key" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "test-key"

    assert HackatimeService.available?
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
  end

  test "fetch_stats returns nil without api key" do
    old_api_key = ENV.delete("HACKATIME_API_KEY")

    result = HackatimeService.fetch_stats("U123")
    assert_nil result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key if old_api_key
  end

  test "fetch_stats returns nil for blank slack_id" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "test-key"

    result = HackatimeService.fetch_stats("")
    assert_nil result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
  end

  test "fetch_trust_status returns trust level" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "dummy-key"

    payload = { "trust_level" => "trusted" }

    singleton_class = HackatimeService.singleton_class
    singleton_class.class_eval do
      alias_method :original_get_json, :get_json
      define_method(:get_json) { |_path, _params = {}| payload }
    end

    result = HackatimeService.fetch_trust_status("U123")
    assert_equal "trusted", result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
    singleton_class.class_eval do
      define_method(:get_json, instance_method(:original_get_json))
      remove_method :original_get_json
    end
  end

  test "fetch_trust_status returns nil without api key" do
    old_api_key = ENV.delete("HACKATIME_API_KEY")

    result = HackatimeService.fetch_trust_status("U123")
    assert_nil result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key if old_api_key
  end

  test "fetch_trust_status returns nil for blank slack_id" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "test-key"

    result = HackatimeService.fetch_trust_status("")
    assert_nil result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
  end

  test "get_all_projects returns sorted projects" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "dummy-key"
    ENV["HACKATIME_START_DATE"] = "2025-01-01"

    all_payload = {
      "data" => {
        "projects" => [
          { "name" => "Alpha", "total_seconds" => 7200 },
          { "name" => "Beta", "total_seconds" => 3600 }
        ],
        "trust_factor" => { "trust_value" => 0 }
      }
    }

    recent_payload = {
      "data" => {
        "projects" => [
          { "name" => "Beta", "total_seconds" => 1800 },
          { "name" => "Alpha", "total_seconds" => 900 }
        ],
        "trust_factor" => { "trust_value" => 0 }
      }
    }

    call_count = 0
    singleton_class = HackatimeService.singleton_class
    singleton_class.class_eval do
      alias_method :original_get_json, :get_json
      define_method(:get_json) do |_path, _params = {}|
        call_count += 1
        call_count == 1 ? all_payload : recent_payload
      end
    end

    service = HackatimeService.new(slack_id: "U123")
    projects = service.get_all_projects

    assert_equal 2, projects.length
    assert_equal "Beta", projects[0]["name"]
    assert_equal 1800, projects[0]["recent_seconds"]
    assert_equal "Alpha", projects[1]["name"]
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
    ENV.delete("HACKATIME_START_DATE")
    singleton_class.class_eval do
      define_method(:get_json, instance_method(:original_get_json))
      remove_method :original_get_json
    end
  end

  test "get_all_projects returns empty array without slack_id" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "dummy-key"

    service = HackatimeService.new(slack_id: nil)
    projects = service.get_all_projects
    assert_equal [], projects
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
  end

  test "get_all_projects returns empty array without api key" do
    old_api_key = ENV.delete("HACKATIME_API_KEY")

    service = HackatimeService.new(slack_id: "U123")
    projects = service.get_all_projects
    assert_equal [], projects
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key if old_api_key
  end

  test "get_trusted_status returns trust level" do
    old_api_key = ENV["HACKATIME_API_KEY"]
    ENV["HACKATIME_API_KEY"] = "dummy-key"

    payload = { "trust_level" => "trusted" }

    singleton_class = HackatimeService.singleton_class
    singleton_class.class_eval do
      alias_method :original_get_json, :get_json
      define_method(:get_json) { |_path, _params = {}| payload }
    end

    service = HackatimeService.new(slack_id: "U123")
    result = service.get_trusted_status
    assert_equal "trusted", result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key
    singleton_class.class_eval do
      define_method(:get_json, instance_method(:original_get_json))
      remove_method :original_get_json
    end
  end

  test "get_trusted_status returns nil without api key" do
    old_api_key = ENV.delete("HACKATIME_API_KEY")

    service = HackatimeService.new(slack_id: "U123")
    result = service.get_trusted_status
    assert_nil result
  ensure
    ENV["HACKATIME_API_KEY"] = old_api_key if old_api_key
  end

  test "default start_date is 30 days ago" do
    old_start = ENV.delete("HACKATIME_START_DATE")
    expected = 30.days.ago.to_date.to_s
    assert_equal expected, HackatimeService.start_date
  ensure
    ENV["HACKATIME_START_DATE"] = old_start
  end

  test "cache_ttl_seconds defaults to 300" do
    old_ttl = ENV.delete("HACKATIME_CACHE_TTL_SECONDS")
    assert_equal 300, HackatimeService.cache_ttl_seconds
  ensure
    ENV["HACKATIME_CACHE_TTL_SECONDS"] = old_ttl if old_ttl
  end

  test "cache_ttl_seconds reads from env" do
    old_ttl = ENV["HACKATIME_CACHE_TTL_SECONDS"]
    ENV["HACKATIME_CACHE_TTL_SECONDS"] = "600"
    assert_equal 600, HackatimeService.cache_ttl_seconds
  ensure
    ENV["HACKATIME_CACHE_TTL_SECONDS"] = old_ttl
  end
end
