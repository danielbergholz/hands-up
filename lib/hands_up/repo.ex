defmodule HandsUp.Repo do
  use Ecto.Repo,
    otp_app: :hands_up,
    adapter: Ecto.Adapters.Postgres
end
