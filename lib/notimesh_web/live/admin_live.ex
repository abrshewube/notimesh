defmodule NotimeshWeb.AdminLive do
  use NotimeshWeb, :live_view

  alias Notimesh.Notifications
  alias Notimesh.Notifications.Delivery

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :refresh)
    end

    socket
    |> assign(:page_title, "NotiMesh Admin Dashboard")
    |> load_data()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={nil}>
      <div class="space-y-8">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-4xl font-bold">NotiMesh Dashboard</h1>
            <p class="mt-2 text-gray-600 dark:text-gray-400">
              Distributed notification system - Node: <%= get_node_name() %>
            </p>
          </div>
        </div>

        <.statistics_cards statistics={@statistics} />

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-2">
            <.notifications_list
              notifications={@notifications}
              status_filter={@status_filter}
              type_filter={@type_filter}
            />
          </div>

          <div>
            <.create_notification_form form={@form} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_event("create_notification", %{"notification" => params}, socket) do
    case Delivery.enqueue(params) do
      {:ok, _notification} ->
        {:noreply,
         socket
         |> put_flash(:info, "Notification enqueued successfully")
         |> load_data()}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create notification: #{inspect(changeset.errors)}")
         |> load_data()}
    end
  end

  @impl true
  def handle_event("filter", %{"status" => status}, socket) when status != "" do
    {:noreply,
     socket
     |> assign(:status_filter, String.to_existing_atom(status))
     |> load_data()}
  end

  @impl true
  def handle_event("filter", %{"type" => type}, socket) when type != "" do
    {:noreply,
     socket
     |> assign(:type_filter, String.to_existing_atom(type))
     |> load_data()}
  end

  @impl true
  def handle_event("filter", _params, socket) do
    {:noreply,
     socket
     |> assign(:status_filter, nil)
     |> assign(:type_filter, nil)
     |> load_data()}
  end

  defp statistics_cards(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
      <.stat_card
        label="Total"
        value={@statistics.total}
        icon="hero-chart-bar"
        color="bg-blue-500"
      />
      <.stat_card
        label="Pending"
        value={@statistics.pending}
        icon="hero-clock"
        color="bg-yellow-500"
      />
      <.stat_card
        label="Processing"
        value={@statistics.processing}
        icon="hero-arrow-path"
        color="bg-purple-500"
      />
      <.stat_card
        label="Delivered"
        value={@statistics.delivered}
        icon="hero-check-circle"
        color="bg-green-500"
      />
      <.stat_card
        label="Failed"
        value={@statistics.failed}
        icon="hero-x-circle"
        color="bg-red-500"
      />
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-6 shadow-sm">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-gray-600 dark:text-gray-400">{@label}</p>
          <p class="mt-2 text-3xl font-bold text-gray-900 dark:text-white">{@value}</p>
        </div>
        <div class={"rounded-full p-3 #{@color}"}>
          <.icon name={@icon} class="h-6 w-6 text-white" />
        </div>
      </div>
    </div>
    """
  end

  defp notifications_list(assigns) do
    ~H"""
    <div class="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 shadow-sm">
      <div class="p-6 border-b border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-semibold">Notifications</h2>
        </div>

        <.filters status_filter={@status_filter} type_filter={@type_filter} />
      </div>

      <div class="divide-y divide-gray-200 dark:divide-gray-700">
        <%= if Enum.empty?(@notifications) do %>
          <div class="p-8 text-center text-gray-500 dark:text-gray-400">
            No notifications found
          </div>
        <% else %>
          <div :for={notification <- @notifications} class="p-6 hover:bg-gray-50 dark:hover:bg-gray-900 transition-colors">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-2">
                  <.status_badge status={notification.status} />
                  <.type_badge type={notification.type} />
                  <span class="text-xs text-gray-500 dark:text-gray-400">
                    <%= notification.node_name %>
                  </span>
                </div>
                <p class="font-medium text-gray-900 dark:text-white">
                  <%= notification.subject || "No subject" %>
                </p>
                <p class="mt-1 text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                  <%= notification.body %>
                </p>
                <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                  To: <%= notification.recipient %>
                </p>
                <%= if notification.error_message do %>
                  <p class="mt-2 text-xs text-red-600 dark:text-red-400">
                    Error: <%= notification.error_message %>
                  </p>
                <% end %>
              </div>
              <div class="ml-4 text-right">
                <p class="text-xs text-gray-500 dark:text-gray-400">
                  <%= Calendar.strftime(notification.inserted_at, "%Y-%m-%d %H:%M") %>
                </p>
                <%= if notification.retry_count > 0 do %>
                  <p class="mt-1 text-xs text-yellow-600 dark:text-yellow-400">
                    Retries: <%= notification.retry_count %>/<%= notification.max_retries %>
                  </p>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp filters(assigns) do
    ~H"""
    <div class="flex gap-2">
      <select
        phx-change="filter"
        name="status"
        class="rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm"
      >
        <option value="">All Statuses</option>
        <option value="pending" selected={@status_filter == :pending}>Pending</option>
        <option value="processing" selected={@status_filter == :processing}>Processing</option>
        <option value="delivered" selected={@status_filter == :delivered}>Delivered</option>
        <option value="failed" selected={@status_filter == :failed}>Failed</option>
        <option value="retrying" selected={@status_filter == :retrying}>Retrying</option>
      </select>

      <select
        phx-change="filter"
        name="type"
        class="rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm"
      >
        <option value="">All Types</option>
        <option value="email" selected={@type_filter == :email}>Email</option>
        <option value="sms" selected={@type_filter == :sms}>SMS</option>
        <option value="slack" selected={@type_filter == :slack}>Slack</option>
      </select>
    </div>
    """
  end

  defp status_badge(assigns) do
    colors = %{
      pending: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
      processing: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200",
      delivered: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
      failed: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
      retrying: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
    }

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{colors[@status]}"}>
      <%= String.capitalize(to_string(@status)) %>
    </span>
    """
  end

  defp type_badge(assigns) do
    colors = %{
      email: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
      sms: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
      slack: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
    }

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{colors[@type]}"}>
      <%= String.upcase(to_string(@type)) %>
    </span>
    """
  end

  defp create_notification_form(assigns) do
    ~H"""
    <div class="rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 p-6 shadow-sm">
      <h2 class="text-xl font-semibold mb-4">Create Notification</h2>

      <.form for={@form} phx-submit="create_notification" id="notification-form">
        <div class="space-y-4">
          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            options={[
              {"Email", "email"},
              {"SMS", "sms"},
              {"Slack", "slack"}
            ]}
            required
          />

          <.input
            field={@form[:recipient]}
            type="text"
            label="Recipient"
            placeholder="email@example.com or +1234567890"
            required
          />

          <.input
            field={@form[:subject]}
            type="text"
            label="Subject"
            placeholder="Notification subject"
          />

          <.input
            field={@form[:body]}
            type="textarea"
            label="Body"
            placeholder="Notification message"
            required
          />

          <button
            type="submit"
            class="w-full rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
          >
            Send Notification
          </button>
        </div>
      </.form>
    </div>
    """
  end

  defp get_node_name do
    case Node.self() do
      :nonode@nohost -> "local"
      node -> to_string(node)
    end
  end

  defp load_data(socket) do
    filters = build_filters(socket.assigns)

    socket
    |> assign(:statistics, Notifications.get_statistics())
    |> assign(:notifications, Notifications.list_notifications(filters ++ [limit: 50]))
    |> assign(:status_filter, socket.assigns[:status_filter])
    |> assign(:type_filter, socket.assigns[:type_filter])
    |> assign(:form, to_form(%{}, as: :notification))
  end

  defp build_filters(assigns) do
    []
    |> maybe_add_filter(:status, assigns[:status_filter])
    |> maybe_add_filter(:type, assigns[:type_filter])
  end

  defp maybe_add_filter(filters, _key, nil), do: filters
  defp maybe_add_filter(filters, key, value), do: [{key, value} | filters]
end
