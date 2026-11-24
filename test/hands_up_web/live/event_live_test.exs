defmodule HandsUpWeb.EventLiveTest do
  use HandsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HandsUp.Events

  setup do
    {:ok, event} = Events.create_event(%{"title" => "Intro to LiveView"})
    %{event: event}
  end

  test "shows the title and the join code", %{conn: conn, event: event} do
    {:ok, view, _html} = live(conn, ~p"/e/#{event.code}")

    assert has_element?(view, "#event-title", "Intro to LiveView")
    assert has_element?(view, "#event-code", display_code(event.code))
  end

  test "is reachable with a lowercase code", %{conn: conn, event: event} do
    {:ok, view, _html} = live(conn, "/e/" <> String.downcase(event.code))

    assert has_element?(view, "#event-code", display_code(event.code))
  end

  test "redirects home with an error for an unknown code", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/", flash: flash}}} = live(conn, ~p"/e/NOPE99")
    assert flash["error"] =~ "NOPE99"
  end

  defp display_code(code) do
    {first, second} = String.split_at(code, 3)
    first <> " " <> second
  end
end
