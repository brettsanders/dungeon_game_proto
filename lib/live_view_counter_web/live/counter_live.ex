defmodule LiveViewCounterWeb.CounterLive do
  use Phoenix.LiveView
  alias LiveViewCounterWeb.CounterView

  @dungeon_width 25
  @dungeon_height 25

  def render(assigns) do
    CounterView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    defaults = %{
      count: 0,
      hero_position: {0, 0}
    }

    new_socket =
      socket
      |> assign(defaults)

    {:ok, new_socket}
  end

  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("dec", _, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("keydown", value, socket) do
    %{"code" => direction} = value
    {x, y} = socket.assigns.hero_position
    # time = socket.assigns.count

    new_hero_position =
      case direction do
        "ArrowLeft" ->
          IO.puts("Decrement X Now")

          # Detect left boundary
          if x - 1 >= 0 do
            {x - 1, y}
          else
            {x, y}
          end

        "ArrowRight" ->
          IO.puts("Increment X Now")

          if x < @dungeon_width do
            {x + 1, y}
          else
            {x, y}
          end

        "ArrowUp" ->
          IO.puts("Increment Y Now")

          if(y < @dungeon_height) do
            {x, y + 1}
          else
            {x, y}
          end

        "ArrowDown" ->
          IO.puts("Decrement Y Now")

          if y > 0 do
            {x, y - 1}
          else
            {x, y}
          end

        _ ->
          IO.puts("Ignore this")
          {x, y}
      end

    new_socket = socket |> assign(hero_position: new_hero_position)

    {:noreply, new_socket}
  end

  def handle_info(:tick, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end
end
