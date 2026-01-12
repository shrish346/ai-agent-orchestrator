defmodule AgentKillSwitchWeb.AgentController do
  use AgentKillSwitchWeb, :controller

  def spawn(conn, _params) do
    case AgentKillSwitch.Agents.Supervisor.start_agent() do
      {:ok, agent_id} ->
        conn
        |> put_status(:created)
        |> json(%{agent_id: agent_id, status: "spawned"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to spawn agent: #{inspect(reason)}"})
    end
  end

  def kill(conn, %{"id" => agent_id}) do
    case AgentKillSwitch.Agents.Supervisor.stop_agent(agent_id) do
      :ok ->
        conn
        |> put_status(:ok)
        |> json(%{agent_id: agent_id, status: "terminated"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found: #{agent_id}"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to kill agent: #{inspect(reason)}"})
    end
  end
end
