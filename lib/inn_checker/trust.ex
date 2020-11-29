defmodule InnChecker.Trust do
  @moduledoc """
  Authorization stuff
  """

  @roles ~w[operator admin]

  def is_active?(%{status: "active"}), do: true
  def is_active?(_), do: false

  def is_admin?(user), do: is_active?(user) and has_role?(user, "admin")

  def is_operator?(user), do: is_active?(user) and has_role?(user, "operator")

  def has_role?(%{role: role} = _user, role), do: role in @roles

  def has_role?(_, _), do: false

  def can?(user, :manage, :operator), do: is_operator?(user) or is_admin?(user)
  def can?(user, :manage, :admin), do: is_admin?(user)
  def can?(_, _, _), do: false
end
