defmodule HandsUp.EventsTest do
  use HandsUp.DataCase, async: true

  alias HandsUp.Events
  alias HandsUp.Events.Event

  describe "generate_code/0" do
    test "returns 6 uppercase letters/digits without ambiguous characters" do
      for _ <- 1..200 do
        assert Events.generate_code() =~ ~r/\A[346789ABCDEFGHJKMNPQRTUVWXY]{6}\z/
      end
    end
  end

  describe "create_event/2" do
    test "creates an event with a title and a join code" do
      assert {:ok, %Event{} = event} = Events.create_event(%{"title" => "  Elixir Meetup  "})
      assert event.title == "Elixir Meetup"
      assert String.length(event.code) == 6
    end

    test "requires a title" do
      assert {:error, changeset} = Events.create_event(%{"title" => "   "})
      assert %{title: ["can't be blank"]} = errors_on(changeset)
    end

    test "limits title length" do
      assert {:error, changeset} = Events.create_event(%{"title" => String.duplicate("a", 121)})
      assert %{title: [_]} = errors_on(changeset)
    end

    test "ignores a code passed in attrs" do
      assert {:ok, event} = Events.create_event(%{"title" => "Talk", "code" => "HACKED"})
      refute event.code == "HACKED"
    end

    test "gives each event a distinct code" do
      codes =
        for i <- 1..20 do
          {:ok, event} = Events.create_event(%{"title" => "Talk #{i}"})
          event.code
        end

      assert length(Enum.uniq(codes)) == 20
    end

    test "retries with a new code when the generated one is already taken" do
      {:ok, existing} = Events.create_event(%{"title" => "First"})
      codes = start_supervised!({Agent, fn -> [existing.code, existing.code, "FRESH3"] end})

      next_code = fn -> Agent.get_and_update(codes, fn [code | rest] -> {code, rest} end) end

      assert {:ok, event} = Events.create_event(%{"title" => "Second"}, generate_code: next_code)
      assert event.code == "FRESH3"
      assert Agent.get(codes, & &1) == []
    end

    test "gives up with an error when codes keep colliding" do
      {:ok, existing} = Events.create_event(%{"title" => "First"})

      assert {:error, changeset} =
               Events.create_event(%{"title" => "Second"}, generate_code: fn -> existing.code end)

      assert %{code: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "get_event_by_code/1" do
    test "finds an event by code, ignoring case and surrounding whitespace" do
      {:ok, event} = Events.create_event(%{"title" => "Talk"})

      assert Events.get_event_by_code(event.code).id == event.id
      assert Events.get_event_by_code(String.downcase(event.code)).id == event.id
      assert Events.get_event_by_code("  #{event.code}\n").id == event.id
    end

    test "returns nil for unknown or blank codes" do
      assert Events.get_event_by_code("NOPE99") == nil
      assert Events.get_event_by_code("") == nil
      assert Events.get_event_by_code("   ") == nil
      assert Events.get_event_by_code(nil) == nil
    end
  end
end
