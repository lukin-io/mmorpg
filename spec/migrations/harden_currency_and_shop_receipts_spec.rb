# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20260910170000_harden_currency_and_shop_receipts")

RSpec.describe HardenCurrencyAndShopReceipts do
  it "stops before schema changes when historical receipts fail preflight" do
    migration = described_class.new
    allow(migration).to receive(:select_one).and_return("invalid_shop_references" => 2, "invalid_wallets" => 0)
    expect(migration).not_to receive(:add_check_constraint)

    expect { migration.up }.to raise_error(ActiveRecord::MigrationError, /invalid_shop_references.*2.*Historical rows were not changed/)
  end

  it "uses a reproducible SQL schema containing an enabled Shop receipt trigger" do
    expect(Rails.application.config.active_record.schema_format).to eq(:sql)
    enabled = ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT tgenabled FROM pg_trigger
      WHERE tgrelid = 'currency_transactions'::regclass
        AND tgname = 'currency_transactions_shop_receipt_guard'
        AND NOT tgisinternal
    SQL
    expect(enabled).to eq("O")
    expect(Rails.root.join("db/structure.sql").read).to include(
      "CREATE FUNCTION public.guard_shop_currency_receipt()",
      "CREATE TRIGGER currency_transactions_shop_receipt_guard"
    )
  end
end
