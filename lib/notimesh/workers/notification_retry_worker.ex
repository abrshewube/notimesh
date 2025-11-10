defmodule Notimesh.Workers.NotificationRetryWorker do
  @moduledoc """
  Oban cron worker for retrying failed notifications.
  """

  use Oban.Worker, queue: :notifications

  alias Notimesh.Notifications
  alias Notimesh.Workers.NotificationWorker

  @impl Oban.Worker
  def perform(_job) do
    retryable = Notifications.get_retryable_notifications()

    Enum.each(retryable, fn notification ->
      %{notification_id: notification.id}
      |> NotificationWorker.new()
      |> Oban.insert()
    end)

    :ok
  end
end
