defmodule HandsUp.Events.Event do
  @moduledoc """
  A live Q&A session, identified publicly by a short join code.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :title, :string
    field :code, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for the user-editable fields. The join code is never cast.
  """
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title])
    |> update_change(:title, &String.trim/1)
    |> validate_required([:title])
    |> validate_length(:title, max: 120)
  end

  @doc """
  Changeset used on creation: validates the title and assigns the join `code`.
  """
  def create_changeset(event, attrs, code) do
    event
    |> changeset(attrs)
    |> put_change(:code, code)
    |> unique_constraint(:code)
  end
end
