defmodule AgentKillSwitchWeb.AgentChannel do
  use Phoenix.Channel
  require Logger

  @impl true
  def join("agents:lobby", _payload, socket) do
    # Subscribe to internal PubSub for agent updates
    :ok = Phoenix.PubSub.subscribe(AgentKillSwitch.PubSub, "agents_internal")
    {:ok, socket}
  end

  @impl true
  def join("agents:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (agents:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Handle internal PubSub messages from agents
  @impl true
  def handle_info({:agent_update, agent_state}, socket) do
    push(socket, "agent_update", %{
      id: agent_state.id,
      status: agent_state.status,
      last_heartbeat: agent_state.last_heartbeat,
      log: agent_state.log
    })
    {:noreply, socket}
  end

  @impl true
  def handle_info({:agent_terminated, agent_id}, socket) do
    push(socket, "agent_terminated", %{id: agent_id})
    {:noreply, socket}
  end

end
