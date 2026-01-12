defmodule AgentKillSwitch.Agents.Supervisor do
  @moduledoc """
  DynamicSupervisor for managing mock AI agents.
  """

  use DynamicSupervisor
  require Logger

  @tick_interval_ms 3000  # Default 3 seconds, more realistic
  @max_log_entries 20     # Default max log entries per agent

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a new mock agent with default configuration.
  """
  def start_agent() do
    start_agent(%{
      tick_interval_ms: @tick_interval_ms,
      max_log_entries: @max_log_entries,
      auto_respawn: false
    })
  end

  @doc """
  Start a new mock agent with custom configuration.
  """
  def start_agent(config) do
    agent_id = generate_agent_id()

    child_spec = %{
      id: {AgentKillSwitch.Agents.MockAgent, agent_id},
      start: {AgentKillSwitch.Agents.MockAgent, :start_link, [agent_id, config]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, _pid} ->
        Logger.info("Started agent #{agent_id}")
        {:ok, agent_id}
      {:error, reason} = error ->
        Logger.error("Failed to start agent: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Stop an agent by ID.
  """
  def stop_agent(agent_id) do
    case lookup_agent_pid(agent_id) do
      {:ok, pid} ->
        case DynamicSupervisor.terminate_child(__MODULE__, pid) do
          :ok ->
            Logger.info("Terminated agent #{agent_id}")
            # Broadcast termination event
            Phoenix.PubSub.broadcast(
              AgentKillSwitch.PubSub,
              "agents_internal",
              {:agent_terminated, agent_id}
            )
            :ok
          {:error, reason} ->
            Logger.error("Failed to terminate agent #{agent_id}: #{inspect(reason)}")
            {:error, reason}
        end
      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Get all active agent IDs.
  """
  def list_agents() do
    Registry.select(AgentKillSwitch.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Get agent state by ID.
  """
  def get_agent_state(agent_id) do
    case lookup_agent_pid(agent_id) do
      {:ok, pid} ->
        AgentKillSwitch.Agents.MockAgent.get_state(pid)
      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Lookup agent PID by ID using Registry.
  """
  def lookup_agent_pid(agent_id) do
    case Registry.lookup(AgentKillSwitch.Registry, agent_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Start the initial set of agents when the application starts.
  """
  def start_initial_agents() do
    Logger.info("Starting initial agents...")

    # Start 3 agents as specified in requirements
    Enum.each(1..3, fn _ ->
      case start_agent() do
        {:ok, agent_id} ->
          Logger.info("Started initial agent: #{agent_id}")
        {:error, reason} ->
          Logger.error("Failed to start initial agent: #{inspect(reason)}")
      end
    end)
  end

  defp generate_agent_id() do
    "agent-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
