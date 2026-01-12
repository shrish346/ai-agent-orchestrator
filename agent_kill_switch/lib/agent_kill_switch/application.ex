defmodule AgentKillSwitch.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AgentKillSwitchWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AgentKillSwitch.PubSub},
      # Start the Endpoint (http/https)
      AgentKillSwitchWeb.Endpoint,
      # Start a worker by calling: AgentKillSwitch.Worker.start_link(arg)
      # {AgentKillSwitch.Worker, arg}
      # Start the Registry for agent ID to PID mapping
      {Registry, keys: :unique, name: AgentKillSwitch.Registry},
      # Start the Agent Supervisor
      AgentKillSwitch.Agents.Supervisor,
      # Start the agent initializer (starts initial agents after everything is up)
      {Task, &AgentKillSwitch.Agents.Supervisor.start_initial_agents/0}
    ]

    # https://hexdocs.pm/elixir/Supervisor.html
    # has sum other strategies and supported options
    opts = [strategy: :one_for_one, name: AgentKillSwitch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AgentKillSwitchWeb.Endpoint.config_change(changed, new: changed, removed: removed)
    :ok
  end
end
