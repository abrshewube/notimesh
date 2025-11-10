defmodule Notimesh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start Erlang distribution
    start_distribution()

    children = [
      NotimeshWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:notimesh, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Notimesh.PubSub},
      Notimesh.Repo,
      {Oban, Application.get_env(:notimesh, Oban)},
      # Start to serve requests, typically the last entry
      NotimeshWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Notimesh.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_distribution do
    node_name = Application.get_env(:notimesh, :node_name, "notimesh@127.0.0.1")
    cookie = Application.get_env(:notimesh, :cookie, "notimesh_cookie")

    unless Node.alive?() do
      case node_name do
        name when is_binary(name) ->
          Node.start(String.to_atom(name), :longnames)

        _ ->
          :ok
      end

      Node.set_cookie(String.to_atom(cookie))
    end

    :ok
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NotimeshWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
