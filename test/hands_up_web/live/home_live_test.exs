defmodule HandsUpWeb.HomeLiveTest do
  use HandsUpWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias HandsUp.Events

  test "renders the create and join forms", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#event-form")
    assert has_element?(view, "#join-form")
  end

  describe "creating an event" do
    test "creates the event and lands on its page", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      result =
        view
        |> form("#event-form", event: %{title: "Elixir Meetup"})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/e/" <> code}}} = result
      assert %{title: "Elixir Meetup"} = Events.get_event_by_code(code)

      {:ok, event_view, _html} = live(conn, "/e/" <> code)
      assert has_element?(event_view, "#event-title", "Elixir Meetup")
    end

    test "shows a validation error for a blank title", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#event-form", event: %{title: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert has_element?(view, "#event-form")
    end

    test "validates on change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert view
             |> form("#event-form", event: %{title: ""})
             |> render_change() =~ "can&#39;t be blank"
    end
  end

  describe "joining an event" do
    setup do
      {:ok, event} = Events.create_event(%{"title" => "Talk"})
      %{event: event}
    end

    test "navigates to the event page", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/")

      result =
        view
        |> form("#join-form", join: %{code: event.code})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: to}}} = result
      assert to == "/e/#{event.code}"
    end

    test "accepts lowercase codes", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/")

      result =
        view
        |> form("#join-form", join: %{code: String.downcase(event.code)})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: to}}} = result
      assert to == "/e/#{event.code}"
    end

    test "shows an error for an unknown code", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> form("#join-form", join: %{code: "NOPE99"})
        |> render_submit()

      assert html =~ "No event found with that code"
      assert has_element?(view, "#join-form")
    end
  end
end
