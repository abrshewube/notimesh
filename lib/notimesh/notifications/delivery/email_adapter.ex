defmodule Notimesh.Notifications.Delivery.EmailAdapter do
  @moduledoc """
  Email delivery adapter using Swoosh.
  """

  alias Notimesh.Mailer
  alias Swoosh.Email

  @behaviour Notimesh.Notifications.Delivery.Adapter

  @impl true
  def deliver(notification) do
    email =
      Email.new()
      |> Email.to(notification.recipient)
      |> Email.subject(notification.subject || "Notification")
      |> Email.html_body(notification.body)
      |> Email.text_body(extract_text(notification.body))

    case Mailer.deliver(email) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp extract_text(html_body) when is_binary(html_body) do
    # Simple HTML to text conversion
    html_body
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp extract_text(_), do: ""
end
