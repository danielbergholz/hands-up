defmodule HandsUp.Events do
  @moduledoc """
  The Events context: creating Q&A events and finding them by join code.
  """

  alias HandsUp.Events.Event
  alias HandsUp.Repo

  # Join codes are read aloud and typed from a projector, so the alphabet drops
  # characters that are easy to confuse: 0, O, 1, I, L, 2, Z, 5 and S.
  # 27 symbols ^ 6 positions ≈ 387 million codes.
  @code_alphabet ~c"346789ABCDEFGHJKMNPQRTUVWXY"
  @code_length 6
  @max_attempts 5

  @doc "Length of a join code."
  def code_length, do: @code_length

  @doc """
  Generates a random join code (not checked for uniqueness).
  """
  def generate_code do
    for _ <- 1..@code_length, into: "", do: <<Enum.random(@code_alphabet)>>
  end

  @doc """
  Creates an event from `attrs` (only `title` is accepted) with a unique join code.

  Uniqueness is enforced by a database unique index; on the rare collision a new
  code is generated and the insert retried.

  ## Options

    * `:generate_code` - zero-arity function returning a code. Defaults to
      `generate_code/0`; mostly useful for tests.
  """
  def create_event(attrs, opts \\ []) do
    generate = Keyword.get(opts, :generate_code, &generate_code/0)
    insert_with_unique_code(attrs, generate, @max_attempts)
  end

  defp insert_with_unique_code(attrs, generate, attempts_left) do
    changeset = Event.create_changeset(%Event{}, attrs, generate.())

    case Repo.insert(changeset) do
      {:error, %Ecto.Changeset{errors: errors}} = error ->
        if Keyword.has_key?(errors, :code) and attempts_left > 1 do
          insert_with_unique_code(attrs, generate, attempts_left - 1)
        else
          error
        end

      result ->
        result
    end
  end

  @doc """
  Returns a changeset for tracking event changes (used by forms).
  """
  def change_event(%Event{} = event, attrs \\ %{}), do: Event.changeset(event, attrs)

  @doc """
  Normalizes user-typed join codes: trims whitespace and upcases.
  """
  def normalize_code(code) when is_binary(code), do: code |> String.trim() |> String.upcase()
  def normalize_code(_), do: ""

  @doc """
  Fetches an event by join code (case-insensitive). Returns `nil` when not found.
  """
  def get_event_by_code(code) do
    case normalize_code(code) do
      "" -> nil
      code -> Repo.get_by(Event, code: code)
    end
  end
end
