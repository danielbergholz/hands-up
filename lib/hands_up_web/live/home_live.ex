defmodule HandsUpWeb.HomeLive do
  use HandsUpWeb, :live_view

  alias HandsUp.Events
  alias HandsUp.Events.Event

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Live Q&A")
     |> assign(:event_form, to_form(Events.change_event(%Event{})))
     |> assign(:join_form, to_form(%{"code" => ""}, as: :join))}
  end

  @impl true
  def handle_event("validate_event", %{"event" => params}, socket) do
    form =
      %Event{}
      |> Events.change_event(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :event_form, form)}
  end

  def handle_event("create_event", %{"event" => params}, socket) do
    case Events.create_event(params) do
      {:ok, event} ->
        {:noreply, push_navigate(socket, to: ~p"/e/#{event.code}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :event_form, to_form(changeset))}
    end
  end

  def handle_event("join_event", %{"join" => %{"code" => code}}, socket) do
    case Events.get_event_by_code(code) do
      %Event{code: code} ->
        {:noreply, push_navigate(socket, to: ~p"/e/#{code}")}

      nil ->
        form =
          to_form(%{"code" => code},
            as: :join,
            errors: [code: {"No event found with that code", []}]
          )

        {:noreply, assign(socket, :join_form, form)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-3 text-center">
        <h1 class="text-4xl font-bold tracking-tight sm:text-5xl">Hands Up</h1>
        <p class="text-lg text-base-content/70">Live Q&amp;A for talks and meetups.</p>
      </div>

      <div class="mt-10 grid gap-6 md:grid-cols-2">
        <section
          id="create-event"
          class="rounded-2xl border border-base-300 bg-base-100 p-6 shadow-sm transition hover:shadow-md"
        >
          <h2 class="text-xl font-semibold">I'm speaking</h2>
          <p class="mb-4 mt-1 text-sm text-base-content/70">
            Create an event and share the code with your audience.
          </p>
          <.form
            for={@event_form}
            id="event-form"
            phx-change="validate_event"
            phx-submit="create_event"
          >
            <.input
              field={@event_form[:title]}
              type="text"
              label="Event title"
              placeholder="Intro to Elixir at Meetup X"
              autocomplete="off"
              phx-debounce="300"
            />
            <.button
              id="create-event-button"
              class="btn btn-primary w-full"
              phx-disable-with="Creating..."
            >
              Create event
            </.button>
          </.form>
        </section>

        <section
          id="join-event"
          class="rounded-2xl border border-base-300 bg-base-100 p-6 shadow-sm transition hover:shadow-md"
        >
          <h2 class="text-xl font-semibold">I'm in the audience</h2>
          <p class="mb-4 mt-1 text-sm text-base-content/70">
            Type the code shown on the screen.
          </p>
          <.form for={@join_form} id="join-form" phx-submit="join_event">
            <.input
              field={@join_form[:code]}
              type="text"
              label="Join code"
              placeholder="ABC123"
              maxlength={Events.code_length()}
              autocomplete="off"
              autocapitalize="characters"
              spellcheck="false"
              class="w-full input font-mono text-lg uppercase tracking-widest"
            />
            <.button
              id="join-event-button"
              class="btn btn-secondary w-full"
              phx-disable-with="Joining..."
            >
              Join
            </.button>
          </.form>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
