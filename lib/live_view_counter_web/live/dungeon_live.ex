defmodule LiveViewCounterWeb.DungeonLive do
  use Phoenix.LiveView
  alias LiveViewCounterWeb.Presence
  alias LiveViewCounterWeb.DungeonView

  @dungeon_width 15
  @dungeon_height 15
  @hero_tick_speed 500

  defp topic(game_id), do: "game:#{game_id}"

  def render(assigns) do
    DungeonView.render("index.html", assigns)
  end

  def mount(%{current_user: current_user}, socket) do
    LiveViewCounterWeb.Endpoint.subscribe(topic(1))

    if connected?(socket) do
      :timer.send_interval(@hero_tick_speed, self(), :tick)
    end

    Presence.track(
      self(),
      topic(1),
      current_user,
      %{
        user: current_user
      }
    )

    initial_hero_position = {0, 0}

    # TODO: May want to DRY this
    # generate_board(player_positions: [{:hero, {0,0}, "Brett"}, {:zombie, {10,10}, "Derek"}])
    initial_board = generate_board()

    initial_board = put_in(initial_board, Tuple.to_list(initial_hero_position), "hero")

    defaults = %{
      count: 0,
      hero_position: initial_hero_position,
      hero_can_move: true,
      game_board: initial_board,
      current_user: current_user,
      users: []
    }

    new_socket =
      socket
      |> assign(defaults)

    {:ok, new_socket}
  end

  def handle_event("keydown", value, socket) do
    %{"code" => direction} = value

    old_hero_position = socket.assigns.hero_position
    hero_can_move = socket.assigns.hero_can_move

    # - - - - - - - - - - - -
    # New Hero position
    new_hero_position = determine_new_hero_position(direction, old_hero_position)

    # - - - - - - - - - - - -
    # Generate the Game Board
    new_game_board = generate_board()
    {x, y} = new_hero_position
    new_game_board = put_in(new_game_board, Tuple.to_list({y, x}), "hero")

    # IO.inspect(game_board)
    LiveViewCounterWeb.Endpoint.broadcast_from(self(), topic(1), "foo", %{
      hero_position: new_hero_position,
      game_board: new_game_board
    })

    new_socket =
      socket
      |> assign(
        hero_position: new_hero_position,
        hero_can_move: hero_can_move,
        game_board: new_game_board
      )

    {:noreply, new_socket}
  end

  def handle_info(%{event: "foo", payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  # def handle_info(
  #       %{event: "presence_diff", payload: _payload},
  #       socket = %{assigns: %{topic: topic}}
  #     ) do
  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    users =
      Presence.list(topic(1))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    IO.inspect(users)

    {:noreply, assign(socket, users: users)}
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    # IO.puts("Tick")
    # IO.puts(:os.system_time(:millisecond))

    new_socket =
      socket
      |> assign(
        count: socket.assigns.count + 1,
        hero_can_move: true
      )

    #  update(socket, :count, &(&1 + 1))
    {:noreply, new_socket}
  end

  defp generate_board do
    for row <- 0..@dungeon_height, into: %{} do
      {row, for(cell <- 0..@dungeon_width, into: %{}, do: {cell, nil})}
    end
  end

  defp determine_new_hero_position(direction, old_hero_position) do
    {x, y} = old_hero_position

    case direction do
      "ArrowLeft" ->
        IO.puts("Decrement Col Now")

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

      "ArrowDown" ->
        IO.puts("Increment Y Now")

        if(y < @dungeon_height) do
          {x, y + 1}
        else
          {x, y}
        end

      "ArrowUp" ->
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

  # def handle_event("inc", _, socket) do
  #   {:noreply, update(socket, :count, &(&1 + 1))}
  # end

  # def handle_event("dec", _, socket) do
  #   {:noreply, update(socket, :count, &(&1 - 1))}
  # end
end
