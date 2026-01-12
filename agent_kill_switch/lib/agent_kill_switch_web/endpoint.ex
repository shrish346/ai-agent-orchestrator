defmodule AgentKillSwitchWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :agent_kill_switch


  socket "/socket", AgentKillSwitchWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :agent_kill_switch,
    gzip: false,
    only: AgentKillSwitchWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.Router, router: AgentKillSwitchWeb.Router
end
