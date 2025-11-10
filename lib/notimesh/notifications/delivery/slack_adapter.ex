defmodule Notimesh.Notifications.Delivery.SlackAdapter do
  @moduledoc """
  Slack delivery adapter using Slack Webhook API.
  Uses Req for HTTP requests.
  """

  @behaviour Notimesh.Notifications.Delivery.Adapter

  @impl true
  def deliver(notification) do
    webhook_url = notification.metadata["webhook_url"] ||
                    Application.get_env(:notimesh, :slack_webhook_url, "")

    if webhook_url == "" do
      {:error, "Slack webhook URL not configured"}
    else
      payload = %{
        text: notification.body,
        channel: notification.metadata["channel"] || "#general",
        username: notification.metadata["username"] || "NotiMesh"
      }

      case Req.post(webhook_url, json: payload) do
        {:ok, %{status: status}} when status in 200..299 -> :ok
        {:ok, response} -> {:error, "Slack API returned status #{response.status}"}
        {:error, reason} -> {:error, inspect(reason)}
      end
    end
  end
end
