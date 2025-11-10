defmodule Notimesh.Notifications.Delivery.Adapter do
  @moduledoc """
  Behaviour for notification delivery adapters.
  """

  @callback deliver(Notimesh.Notifications.Notification.t()) :: :ok | {:error, String.t()}
end
