defmodule Notimesh.Workers.NotificationWorker do
  @moduledoc """
  Oban worker for processing notifications.
  """

  use Oban.Worker, queue: :notifications, max_attempts: 1

  alias Notimesh.Notifications
  alias Notimesh.Notifications.Delivery.EmailAdapter
  alias Notimesh.Notifications.Delivery.SMSAdapter
  alias Notimesh.Notifications.Delivery.SlackAdapter

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"notification_id" => notification_id}}) do
    notification = Notifications.get_notification!(notification_id)

    # Update status to processing
    Notifications.update_notification(notification, %{status: :processing})

    # Select adapter based on notification type
    adapter = get_adapter(notification.type)

    # Deliver notification
    case adapter.deliver(notification) do
      :ok ->
        Notifications.mark_delivered(notification)
        :ok

      {:error, error_message} ->
        # Increment retry count and schedule retry if needed
        updated = Notifications.increment_retry(notification)

        if updated.status == :retrying do
          # Schedule retry with exponential backoff
          schedule_retry(updated)
        else
          Notifications.mark_failed(updated, error_message)
        end

        {:error, error_message}
    end
  end

  defp get_adapter(:email), do: EmailAdapter
  defp get_adapter(:sms), do: SMSAdapter
  defp get_adapter(:slack), do: SlackAdapter

  defp schedule_retry(notification) do
    # Exponential backoff: 2^retry_count minutes
    backoff_minutes = :math.pow(2, notification.retry_count) |> round()
    schedule_in = backoff_minutes * 60

    %{notification_id: notification.id}
    |> __MODULE__.new(schedule_in: schedule_in)
    |> Oban.insert()
  end
end
