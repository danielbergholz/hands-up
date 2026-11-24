defmodule HandsUp.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string, null: false
      add :code, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:events, [:code])
  end
end
