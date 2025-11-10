defmodule Notimesh.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :recipient, :string, null: false
      add :subject, :string
      add :body, :text, null: false
      add :metadata, :map, default: %{}
      add :retry_count, :integer, default: 0
      add :max_retries, :integer, default: 3
      add :delivered_at, :utc_datetime
      add :failed_at, :utc_datetime
      add :error_message, :text
      add :node_name, :string

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:status])
    create index(:notifications, [:type])
    create index(:notifications, [:inserted_at])
    create index(:notifications, [:node_name])
  end
end
