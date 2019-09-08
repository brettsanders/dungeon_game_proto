defmodule LiveViewCounterWeb.DungeonLive do
  use Phoenix.LiveView
  alias LiveViewCounterWeb.DungeonView

  @dungeon_width 15
  @dungeon_height 15
  @hero_tick_speed 500

  def render(assigns) do
    DungeonView.render("index.html", assigns)
  end

  def mount(%{current_user: current_user}, socket) do
    if connected?(socket) do
      :timer.send_interval(@hero_tick_speed, self(), :tick)
    end

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
      current_user: current_user
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

    # - - - - - - - - - - - -
    # New Hero position
    new_hero_position = determine_new_hero_position(direction, old_hero_position)

    # - - - - - - - - - - - -
    # BUGGY
    # One Movement per Tick
    # hero_moved? = old_hero_position != new_hero_position

    # hero_position =
    #   case hero_can_move do
    #     true ->
    #       new_hero_position

    #     false ->
    #       old_hero_position

    #     _ ->
    #       old_hero_position
    #   end

    # hero_can_move = if hero_moved?, do: false

    # - - - - - - - - - - - -
    # Generate the Game Board
    new_game_board = generate_board()
    {x, y} = new_hero_position
    new_game_board = put_in(new_game_board, Tuple.to_list({y, x}), "hero")

    # IO.inspect(game_board)

    new_socket =
      socket
      |> assign(
        hero_position: new_hero_position,
        hero_can_move: hero_can_move,
        game_board: new_game_board
      )

    {:noreply, new_socket}
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
end
