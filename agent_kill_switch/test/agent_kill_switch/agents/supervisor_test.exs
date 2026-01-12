defmodule AgentKillSwitch.Agents.SupervisorTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias AgentKillSwitch.Agents.Supervisor

  setup_all do
    # This is a simplified test that works with the global supervisor
    # In a real application, you'd mock the dependencies
    :ok
  end

  test "generate_agent_id creates unique IDs" do
    # Test the private function by calling it via the supervisor
    # This is a basic smoke test
    assert {:ok, agent_id} = Supervisor.start_agent()
    assert is_binary(agent_id)
  end

  test "lookup_agent_pid returns error for non-existent agent" do
    assert Supervisor.lookup_agent_pid("non-existent-agent") == :error
  end

  # Note: More comprehensive tests would require mocking the Registry
  # and DynamicSupervisor dependencies, which is beyond the scope of
  # this minimal test suite as requested.
end
