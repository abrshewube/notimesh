defmodule Notimesh.Notifications.Delivery.SMSAdapter do
  @moduledoc """
  SMS delivery adapter using HTTP API (Twilio, etc).
  Uses Req for HTTP requests.
  """

  @behaviour Notimesh.Notifications.Delivery.Adapter

  @impl true
  def deliver(notification) do
    # Example implementation - replace with actual SMS provider API
    # For demo purposes, we'll simulate SMS delivery
    api_url = Application.get_env(:notimesh, :sms_api_url, "https://api.sms-provider.com/send")
    api_key = Application.get_env(:notimesh, :sms_api_key, "")

    if api_key == "" do
      # Simulate delivery for development
      Process.sleep(100)
      :ok
    else
      case Req.post(api_url,
             json: %{
               to: notification.recipient,
               message: notification.body
             },
             headers: [{"Authorization", "Bearer #{api_key}"}]
           ) do
        {:ok, %{status: status}} when status in 200..299 -> :ok
        {:ok, response} -> {:error, "SMS API returned status #{response.status}"}
        {:error, reason} -> {:error, inspect(reason)}
      end
    end
  end
end
