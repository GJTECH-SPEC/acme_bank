defmodule BankWeb.TransferController do
  use BankWeb.Web, :controller

  plug BankWeb.Authentication.Require

  def new(conn, _params) do
    customer = conn.assigns.current_customer
    transfer = BankWeb.Transfer.changeset(customer, %BankWeb.Transfer{})
    render conn, "new.html", transfer: transfer
  end

  def create(conn, %{"transfer" => transfer_params}) do
    customer = conn.assigns.current_customer

    case BankWeb.Transfer.create(customer, transfer_params) do
      {:ok, transfer} ->
        send_message(transfer)
        redirect conn, to: account_path(conn, :show)
      {:error, changeset} ->
        changeset = %{changeset | action: :transfer}
        render conn, "new.html", transfer: changeset
    end
  end

  defp send_message(transfer) do
    amount = BankWeb.AccountView.format_money(transfer.amount_cents)
    subject = "You've received #{amount} from #{transfer.source_customer.username}"
    :ok = BankWeb.Messenger.send(transfer.destination_username, subject, subject)
  end
end
