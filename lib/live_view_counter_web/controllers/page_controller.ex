defmodule LiveViewCounterWeb.PageController do
  use LiveViewCounterWeb, :controller
  alias Phoenix.LiveView
  alias LiveViewCounterWeb.DungeonLive

  def index(conn, params) do
    current_user = params["current_user"] || "Unknown"

    LiveView.Controller.live_render(
      conn,
      DungeonLive,
      session: %{current_user: current_user}
    )
  end

  def home(conn, _params) do
    render(conn, "home.html")
  end
end
