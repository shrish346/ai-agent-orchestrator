defmodule AgentKillSwitchWeb.Router do
  use AgentKillSwitchWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AgentKillSwitchWeb do
    pipe_through :api

    post "/agents", AgentController, :spawn
    post "/agents/:id/kill", AgentController, :kill
  end

end
