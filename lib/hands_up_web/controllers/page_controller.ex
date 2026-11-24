defmodule HandsUpWeb.PageController do
  use HandsUpWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
