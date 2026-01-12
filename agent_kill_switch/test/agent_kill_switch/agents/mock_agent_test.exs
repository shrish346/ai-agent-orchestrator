defmodule AgentKillSwitch.Agents.MockAgentTest do
  use ExUnit.Case, async: false

  alias AgentKillSwitch.Agents.MockAgent

  test "agent struct has correct fields" do
    config = %{
      tick_interval_ms: 1000,
      max_log_entries: 20,
      auto_respawn: false
    }

    state = %MockAgent{
      id: "test-agent",
      status: :healthy,
      last_heartbeat: DateTime.utc_now(),
      log: [],
      tick_interval_ms: config.tick_interval_ms,
      max_log_entries: config.max_log_entries,
      auto_respawn: config.auto_respawn
    }

    assert state.id == "test-agent"
    assert state.status == :healthy
    assert is_struct(state.last_heartbeat, DateTime)
    assert state.log == []
    assert state.tick_interval_ms == 1000
    assert state.max_log_entries == 20
    assert state.auto_respawn == false
  end

  # Note: Integration tests with running GenServers would require
  # more complex setup and are beyond the scope of this minimal
  # test suite as requested.
end
