defmodule Notimesh.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @types ~w(email sms slack)a
  @statuses ~w(pending processing delivered failed retrying)a

  schema "notifications" do
    field :type, Ecto.Enum, values: @types
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :recipient, :string
    field :subject, :string
    field :body, :text
    field :metadata, :map, default: %{}
    field :retry_count, :integer, default: 0
    field :max_retries, :integer, default: 3
    field :delivered_at, :utc_datetime
    field :failed_at, :utc_datetime
    field :error_message, :text
    field :node_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :type,
      :status,
      :recipient,
      :subject,
      :body,
      :metadata,
      :retry_count,
      :max_retries,
      :delivered_at,
      :failed_at,
      :error_message,
      :node_name
    ])
    |> validate_required([:type, :recipient, :body])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
  end
end
