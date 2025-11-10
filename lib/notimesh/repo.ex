defmodule Notimesh.Repo do
  use Ecto.Repo,
    otp_app: :notimesh,
    adapter: Ecto.Adapters.Postgres
end
