defmodule Macchinista.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Macchinista.Repo

  alias Macchinista.Accounts.{ User, Session }

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    Repo.transaction fn ->
      user =
        attrs
        |> User.create_changeset()
        |> Repo.insert()
      case user do
        {:ok, user } ->
          #create_log(user, :user, :insert, :success, user)
          {:ok, user}
        {:error, _} ->
          Repo.rollback(:internal)
      end
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def create_session(user) do
    user
    |> Session.create!
    |> Session.create_changeset(%{user_id: user.id, active: true})
    |> Repo.insert()
  end

  def inactivate_session(%Session{id: id}) do
    Session
    |> Repo.get!(id)
    |> Session.inactivate()
    |> Repo.update()
  end

  def login(%{email: email, password: password}) do
    with \
      user <- get_user_by_email(email), \
      true <- Bcrypt.verify_pass(password, user.password_hash) do
      create_session(user)
    else
      {:error, _} = response -> response
      false -> {:error, "Invalid credentials"}
      _ -> {:error, "Unknown Error"}
    end
  end
end