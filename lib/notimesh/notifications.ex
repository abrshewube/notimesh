defmodule Notimesh.Notifications do
  @moduledoc """
  The Notifications context.
  """

  import Ecto.Query, warn: false
  alias Notimesh.Repo
  alias Notimesh.Notifications.Notification

  @doc """
  Returns the list of notifications.
  """
  def list_notifications(filters \\ []) do
    base_query()
    |> apply_filters(filters)
    |> Repo.all()
  end

  @doc """
  Gets a single notification.
  """
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Creates a notification.
  """
  def create_notification(attrs \\ %{}) do
    node_name = get_node_name()

    %Notification{}
    |> Notification.changeset(Map.merge(attrs, %{node_name: node_name}))
    |> Repo.insert()
  end

  @doc """
  Updates a notification.
  """
  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Marks a notification as delivered.
  """
  def mark_delivered(%Notification{} = notification) do
    update_notification(notification, %{
      status: :delivered,
      delivered_at: DateTime.utc_now()
    })
  end

  @doc """
  Marks a notification as failed.
  """
  def mark_failed(%Notification{} = notification, error_message) do
    attrs = %{
      status: :failed,
      failed_at: DateTime.utc_now(),
      error_message: error_message
    }

    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Increments retry count and updates status.
  """
  def increment_retry(%Notification{} = notification) do
    new_retry_count = notification.retry_count + 1

    attrs =
      if new_retry_count >= notification.max_retries do
        %{
          retry_count: new_retry_count,
          status: :failed,
          failed_at: DateTime.utc_now()
        }
      else
        %{
          retry_count: new_retry_count,
          status: :retrying
        }
      end

    update_notification(notification, attrs)
  end

  @doc """
  Gets notifications that need retrying.
  """
  def get_retryable_notifications do
    base_query()
    |> where([n], n.status in [:failed, :retrying])
    |> where([n], n.retry_count < n.max_retries)
    |> Repo.all()
  end

  @doc """
  Gets statistics for the dashboard.
  """
  def get_statistics do
    total = Repo.aggregate(base_query(), :count, :id)

    by_status =
      base_query()
      |> group_by([n], n.status)
      |> select([n], {n.status, count(n.id)})
      |> Repo.all()
      |> Map.new()

    by_type =
      base_query()
      |> group_by([n], n.type)
      |> select([n], {n.type, count(n.id)})
      |> Repo.all()
      |> Map.new()

    %{
      total: total,
      by_status: by_status,
      by_type: by_type,
      pending: Map.get(by_status, :pending, 0),
      processing: Map.get(by_status, :processing, 0),
      delivered: Map.get(by_status, :delivered, 0),
      failed: Map.get(by_status, :failed, 0)
    }
  end

  defp base_query do
    from(n in Notification, order_by: [desc: n.inserted_at])
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:status, status} | rest]) do
    query
    |> where([n], n.status == ^status)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:type, type} | rest]) do
    query
    |> where([n], n.type == ^type)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:limit, limit} | rest]) do
    query
    |> limit(^limit)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)

  defp get_node_name do
    case Node.self() do
      :nonode@nohost -> "local"
      node -> to_string(node)
    end
  end
end
