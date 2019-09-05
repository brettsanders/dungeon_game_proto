defmodule LiveViewCounterWeb.CounterLive do
  use Phoenix.LiveView
  alias LiveViewCounterWeb.CounterView

  @dungeon_width 25
  @dungeon_height 25
  @hero_tick_speed 500

  def render(assigns) do
    CounterView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    if connected?(socket) do
      :timer.send_interval(@hero_tick_speed, self(), :tick)
    end

    defaults = %{
      count: 0,
      hero_position: {0, 0},
      hero_can_move: true
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

    old_hero_position = socket.assigns.hero_position
    hero_can_move = socket.assigns.hero_can_move

    new_hero_position = determine_new_hero_position(direction, old_hero_position)
    hero_moved? = old_hero_position != new_hero_position

    hero_position =
      case hero_can_move do
        true ->
          new_hero_position

        false ->
          old_hero_position

        _ ->
          old_hero_position
      end

    hero_can_move = if hero_moved?, do: false

    new_socket =
      socket
      |> assign(
        hero_position: hero_position,
        hero_can_move: hero_can_move
      )

    {:noreply, new_socket}
  end

  def handle_info(:tick, socket) do
    IO.puts("Tick")
    IO.puts(:os.system_time(:millisecond))

    new_socket =
      socket
      |> assign(
        count: socket.assigns.count + 1,
        hero_can_move: true
      )

    #  update(socket, :count, &(&1 + 1))
    {:noreply, new_socket}
  end

  defp determine_new_hero_position(direction, old_hero_position) do
    {x, y} = old_hero_position

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
  end
end
