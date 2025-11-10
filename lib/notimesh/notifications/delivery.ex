defmodule Notimesh.Notifications.Delivery do
  @moduledoc """
  Delivery module that routes notifications to appropriate adapters.
  """

  alias Notimesh.Notifications
  alias Notimesh.Workers.NotificationWorker

  @doc """
  Enqueues a notification for delivery.
  """
  def enqueue(attrs \\ %{}) do
    case Notifications.create_notification(attrs) do
      {:ok, notification} ->
        # Enqueue Oban job
        %{notification_id: notification.id}
        |> NotificationWorker.new()
        |> Oban.insert()

        {:ok, notification}

      error ->
        error
    end
  end
end
