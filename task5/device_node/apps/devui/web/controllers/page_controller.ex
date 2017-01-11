defmodule DevUI.PageController do
  use DevUI.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
