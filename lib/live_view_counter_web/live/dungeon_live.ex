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
    IO.puts("MOUNT!!!")

    LiveViewCounterWeb.Endpoint.subscribe(topic(1))
    IO.inspect(Presence.list(topic(1)))

    if connected?(socket) do
      :timer.send_interval(@hero_tick_speed, self(), :tick)
    end

    initial_hero_position = {0, 0}

    # Can / should I use presence to track the User positions ?
    # Issue: Mount seems to clear the positions for all

    Presence.track(
      self(),
      topic(1),
      current_user,
      %{
        user: current_user
      }
    )

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
      users: [],
      user_positions: %{current_user => initial_hero_position},
      latest_news: {nil, nil}
    }

    new_socket =
      socket
      |> assign(defaults)

    {:ok, new_socket}
  end

  def handle_event("keydown", value, socket) do
    IO.inspect(value)
    %{"code" => direction} = value

    # old_hero_position = socket.assigns.hero_position
    old_hero_position = socket.assigns.user_positions[socket.assigns.current_user] || {0, 0}
    hero_can_move = socket.assigns.hero_can_move

    # - - - - - - - - - - - -
    # New Hero position
    new_hero_position = determine_new_hero_position(direction, old_hero_position)

    # - - - - - - - - - - - -
    # Generate the Game Board
    new_game_board = generate_board()
    # {x, y} = new_hero_position
    # new_game_board = put_in(new_game_board, Tuple.to_list({y, x}), "hero")

    user_positions = socket.assigns.user_positions
    current_user = socket.assigns.current_user
    user_positions = Map.put(user_positions, current_user, new_hero_position)

    # Generate some Latest News
    random_number = Enum.random(0..10)

    # Basic Naive collision detection
    # IO.inspect(user_positions)
    user_coordinates = Map.values(user_positions)

    latest_news =
      if random_number == 5 do
        {"Zombie Attack! +100", DateTime.utc_now()}
      else
        {nil, nil}
      end

    new_game_board =
      Enum.reduce(user_positions, new_game_board, fn user_position, acc ->
        {name, {x, y}} = user_position
        put_in(acc, Tuple.to_list({y, x}), name)
      end)

    # IO.inspect(game_board)
    LiveViewCounterWeb.Endpoint.broadcast_from(self(), topic(1), "foo", %{
      hero_position: new_hero_position,
      game_board: new_game_board,
      user_positions: user_positions,
      latest_news: latest_news
    })

    new_socket =
      socket
      |> assign(
        hero_position: new_hero_position,
        hero_can_move: hero_can_move,
        game_board: new_game_board,
        user_positions: user_positions,
        latest_news: latest_news
      )

    {:noreply, new_socket}
  end

  def handle_info(%{event: "foo", payload: state}, socket) do
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    users =
      Presence.list(topic(1))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    # IO.inspect(users)

    {:noreply, assign(socket, users: users)}
  end

  def handle_info(:tick, socket) do
    # IO.puts("Tick")
    # IO.puts(:os.system_time(:millisecond))
    # IO.inspect(socket.assigns.latest_news)
    latest_news = socket.assigns.latest_news

    # IO.puts("latest news...")
    # IO.inspect(latest_news)
    # IO.puts("latest news...")

    # if latest_news == {nil, nil} do
    #   IO.puts("No news!")
    # else
    #   IO.puts("In here dude")
    #   {latest_news_message, latest_news_time} = latest_news
    #   IO.inspect(DateTime.diff(DateTime.utc_now(), latest_news_time))
    #   # IO.inspect(DateTime.diff(latest_news_time, DateTime.utc_now())
    # end

    # IO.puts(DateTime.diff(latest_news_time, DateTime.utc_now()))

    new_socket =
      socket
      |> assign(
        count: socket.assigns.count + 1,
        hero_can_move: true,
        latest_news: socket.assigns.latest_news
      )

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
