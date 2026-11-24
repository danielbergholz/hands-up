defmodule HandsUpWeb.EventLive do
  use HandsUpWeb, :live_view

  alias HandsUp.Events

  @impl true
  def mount(%{"code" => code}, _session, socket) do
    case Events.get_event_by_code(code) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "No event found with code #{String.upcase(code)}")
         |> push_navigate(to: ~p"/")}

      event ->
        {:ok,
         socket
         |> assign(:page_title, event.title)
         |> assign(:event, event)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="event" class="space-y-10 py-8 text-center">
        <h1 id="event-title" class="text-4xl font-bold tracking-tight sm:text-6xl">
          {@event.title}
        </h1>

        <div class="space-y-3">
          <p class="text-lg uppercase tracking-widest text-base-content/60">Join with code</p>
          <p
            id="event-code"
            class="font-mono text-7xl font-extrabold tracking-[0.15em] text-primary sm:text-9xl"
            aria-label={"Join code: " <> Enum.join(String.graphemes(@event.code), " ")}
          >
            {display_code(@event.code)}
          </p>
        </div>

        <p id="event-join-url" class="text-xl text-base-content/70">
          {url(~p"/e/#{@event.code}")}
        </p>
      </div>
    </Layouts.app>
    """
  end

  # Splits the code in the middle ("ABC123" -> "ABC 123") so it is easier to read
  # from far away. Display only: the stored code is never changed.
  defp display_code(code) do
    {first, second} = String.split_at(code, div(String.length(code), 2))
    first <> " " <> second
  end
end
