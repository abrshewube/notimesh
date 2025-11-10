defmodule NotimeshWeb.PageController do
  use NotimeshWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
