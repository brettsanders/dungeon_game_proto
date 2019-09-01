defmodule LiveViewCounterWeb.CounterLive do
  use Phoenix.LiveView
  alias LiveViewCounterWeb.CounterView

  def render(assigns) do
    CounterView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    {:ok, assign(socket, :count, 0)}
  end

  def handle_event("inc", _, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("dec", _, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_info(:tick, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end
end
