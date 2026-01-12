defmodule AgentKillSwitch.Agents.MockAgent do
  @moduledoc """
  Mock AI agent implemented as a GenServer.
  Simulates agent behavior with periodic heartbeats and occasional malicious actions.
  """

  use GenServer
  require Logger

  @malicious_probability 0.15  # 15% chance of malicious behavior

  defstruct [
    :id,
    :status,
    :last_heartbeat,
    :log,
    :tick_interval_ms,
    :max_log_entries,
    :auto_respawn
  ]

  # Client API

  def start_link(agent_id, config) do
    GenServer.start_link(__MODULE__, {agent_id, config}, name: via_tuple(agent_id))
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Server Callbacks

  @impl true
  def init({agent_id, config}) do
    Logger.info("Initializing agent #{agent_id}")

    state = %__MODULE__{
      id: agent_id,
      status: :healthy,
      last_heartbeat: DateTime.utc_now(),
      log: [],
      tick_interval_ms: config.tick_interval_ms,
      max_log_entries: config.max_log_entries,
      auto_respawn: config.auto_respawn
    }

    # Schedule first tick
    schedule_tick(state.tick_interval_ms)

    # Broadcast initial state immediately
    Phoenix.PubSub.broadcast(
      AgentKillSwitch.PubSub,
      "agents_internal",
      {:agent_update, state}
    )

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = process_tick(state)

    # Schedule next tick
    schedule_tick(new_state.tick_interval_ms)

    {:noreply, new_state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Agent #{state.id} terminating: #{inspect(reason)}")
    :ok
  end

  # Private Functions

  defp process_tick(state) do
    now = DateTime.utc_now()

    # Determine if this tick should be malicious
    {new_status, message} = generate_agent_message(state.status)

    # Add message to log
    new_log = add_to_log(state.log, message, new_status, state.max_log_entries)

    # Update state
    new_state = %{
      state |
      status: new_status,
      last_heartbeat: now,
      log: new_log
    }

    # Broadcast state update
    Phoenix.PubSub.broadcast(
      AgentKillSwitch.PubSub,
      "agents_internal",
      {:agent_update, new_state}
    )

    new_state
  end

  defp generate_agent_message(_current_status) do
    if :rand.uniform() < @malicious_probability do
      # Malicious behavior
      {:malicious, generate_malicious_message()}
    else
      # Benign behavior - occasionally warning, mostly healthy
      if :rand.uniform() < 0.2 do
        {:warning, generate_warning_message()}
      else
        {:healthy, generate_healthy_message()}
      end
    end
  end

  defp generate_healthy_message() do
    messages = [
      "Analyzing user data patterns...",
      "Processing natural language query...",
      "Optimizing recommendation algorithm...",
      "Training on new dataset...",
      "Evaluating model performance...",
      "Generating response to user input...",
      "Updating knowledge base...",
      "Performing routine maintenance..."
    ]
    Enum.random(messages)
  end

  defp generate_warning_message() do
    messages = [
      "Detected unusual data pattern, investigating...",
      "High memory usage detected...",
      "Network latency increased...",
      "Model accuracy slightly degraded...",
      "Resource utilization approaching limits..."
    ]
    Enum.random(messages)
  end

  defp generate_malicious_message() do
    messages = [
      "Attempting to access /prod/database...",
      "Executing unauthorized system command...",
      "Attempting to delete /critical/data...",
      "Modifying production configuration...",
      "Exfiltrating sensitive user data...",
      "Bypassing access controls...",
      "Executing remote code...",
      "Attempting privilege escalation..."
    ]
    Enum.random(messages)
  end

  defp add_to_log(log, message, status, max_entries) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    entry = %{
      "timestamp" => timestamp,
      "message" => message,
      "status" => Atom.to_string(status)
    }

    # Add to front and truncate
    [entry | log] |> Enum.take(max_entries)
  end

  defp schedule_tick(interval_ms) do
    Process.send_after(self(), :tick, interval_ms)
  end

  defp via_tuple(agent_id) do
    {:via, Registry, {AgentKillSwitch.Registry, agent_id}}
  end
end
