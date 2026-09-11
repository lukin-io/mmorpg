# frozen_string_literal: true

class HardenCurrencyAndShopReceipts < ActiveRecord::Migration[8.1]
  SHOP_REASONS = "'shop.purchase', 'shop.sale'"

  def up
    preflight!

    add_check_constraint :currency_wallets,
      "nv_balance >= 0 AND nv_balance < 10000000000",
      name: "currency_wallets_bounded_balance"
    add_check_constraint :currency_transactions,
      "amount > -10000000000 AND amount < 10000000000 AND amount <> 0",
      name: "currency_transactions_finite_nonzero_amount"
    add_check_constraint :currency_transactions,
      "balance_after >= 0 AND balance_after < 10000000000",
      name: "currency_transactions_bounded_balance"

    # Metadata remains the receipt-writing API. Stored generated references
    # provide real foreign keys without a second independently writable value.
    add_column :currency_transactions, :shop_offer_id, :virtual, type: :bigint,
      as: "CASE WHEN reason IN (#{SHOP_REASONS}) THEN (metadata ->> 'shop_offer_id')::bigint END", stored: true
    add_column :currency_transactions, :shop_account_id, :virtual, type: :bigint,
      as: "CASE WHEN reason IN (#{SHOP_REASONS}) THEN (metadata ->> 'shop_account_id')::bigint END", stored: true
    add_check_constraint :currency_transactions, <<~SQL.squish, name: "currency_transactions_shop_references"
      reason NOT IN (#{SHOP_REASONS}) OR (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(metadata -> 'shop_offer_id') = 'number'
        AND jsonb_typeof(metadata -> 'shop_account_id') = 'number'
        AND shop_offer_id IS NOT NULL AND shop_offer_id > 0
        AND shop_account_id IS NOT NULL AND shop_account_id > 0
      )
    SQL
    add_check_constraint :currency_transactions, <<~SQL.squish, name: "currency_transactions_shop_amount_direction"
      (reason <> 'shop.purchase' OR amount < 0) AND (reason <> 'shop.sale' OR amount > 0)
    SQL
    add_index :currency_transactions, :shop_offer_id, unique: true,
      where: "shop_offer_id IS NOT NULL", name: "index_currency_transactions_unique_shop_offer"
    add_index :currency_transactions, :shop_account_id
    add_foreign_key :currency_transactions, :world_action_offers, column: :shop_offer_id
    add_foreign_key :currency_transactions, :shop_accounts

    execute <<~SQL
      CREATE FUNCTION guard_shop_currency_receipt() RETURNS trigger
      LANGUAGE plpgsql AS $function$
      BEGIN
        IF TG_OP = 'DELETE' THEN
          IF OLD.reason IN (#{SHOP_REASONS}) THEN
            RAISE EXCEPTION 'Shop purchase/sale receipts are append-only'
              USING ERRCODE = '23514', CONSTRAINT = 'currency_transactions_shop_append_only';
          END IF;
        ELSIF TG_OP = 'UPDATE' THEN
          IF OLD.reason IN (#{SHOP_REASONS}) OR NEW.reason IN (#{SHOP_REASONS}) THEN
            RAISE EXCEPTION 'Shop purchase/sale receipts are append-only'
              USING ERRCODE = '23514', CONSTRAINT = 'currency_transactions_shop_append_only';
          END IF;
        ELSIF NEW.reason IN (#{SHOP_REASONS}) THEN
          IF NOT EXISTS (
            SELECT 1
            FROM world_action_offers offers
            JOIN characters owners ON owners.id = offers.character_id
            JOIN currency_wallets wallets ON wallets.id = NEW.currency_wallet_id
            WHERE offers.id = NEW.shop_offer_id
              AND owners.user_id = wallets.user_id
              AND offers.action_type = CASE NEW.reason WHEN 'shop.purchase' THEN 'shop_buy' ELSE 'shop_sell' END
              AND offers.metadata ->> 'shop_account_id' = NEW.shop_account_id::text
          ) THEN
            RAISE EXCEPTION 'Shop receipt references do not match its wallet, action and account'
              USING ERRCODE = '23514', CONSTRAINT = 'currency_transactions_shop_reference_match';
          END IF;
        END IF;
        RETURN NULL;
      END;
      $function$;

      CREATE TRIGGER currency_transactions_shop_receipt_guard
        AFTER INSERT OR UPDATE OR DELETE ON currency_transactions
        FOR EACH ROW EXECUTE FUNCTION guard_shop_currency_receipt();
    SQL
  end

  def down
    execute "DROP TRIGGER currency_transactions_shop_receipt_guard ON currency_transactions"
    execute "DROP FUNCTION guard_shop_currency_receipt()"
    remove_foreign_key :currency_transactions, column: :shop_account_id
    remove_foreign_key :currency_transactions, column: :shop_offer_id
    remove_index :currency_transactions, :shop_account_id
    remove_index :currency_transactions, name: "index_currency_transactions_unique_shop_offer"
    remove_check_constraint :currency_transactions, name: "currency_transactions_shop_amount_direction"
    remove_check_constraint :currency_transactions, name: "currency_transactions_shop_references"
    remove_column :currency_transactions, :shop_account_id
    remove_column :currency_transactions, :shop_offer_id
    remove_check_constraint :currency_transactions, name: "currency_transactions_bounded_balance"
    remove_check_constraint :currency_transactions, name: "currency_transactions_finite_nonzero_amount"
    remove_check_constraint :currency_wallets, name: "currency_wallets_bounded_balance"
  end

  private

  # Stop before changing the schema when historical rows cannot satisfy the
  # contract. Report aggregate counts only; never rewrite old receipts or money.
  def preflight!
    counts = select_one(<<~SQL)
      WITH receipts AS (
        SELECT *,
          #{safe_reference("shop_offer_id")} AS offer_id,
          #{safe_reference("shop_account_id")} AS account_id
        FROM currency_transactions WHERE reason IN (#{SHOP_REASONS})
      )
      SELECT
        (SELECT count(*) FROM currency_wallets WHERE NOT (nv_balance >= 0 AND nv_balance < 10000000000)) AS invalid_wallets,
        (SELECT count(*) FROM currency_transactions WHERE NOT (amount > -10000000000 AND amount < 10000000000 AND amount <> 0)) AS invalid_amounts,
        (SELECT count(*) FROM currency_transactions WHERE NOT (balance_after >= 0 AND balance_after < 10000000000)) AS invalid_balances,
        (SELECT count(*) FROM (
          SELECT offer_id FROM receipts WHERE offer_id IS NOT NULL GROUP BY offer_id HAVING count(*) > 1
        ) duplicates) AS duplicate_offer_groups,
        count(*) FILTER (WHERE r.offer_id IS NULL OR r.account_id IS NULL) AS invalid_shop_references,
        count(*) FILTER (WHERE o.id IS NULL OR a.id IS NULL) AS missing_shop_parents,
        count(*) FILTER (WHERE c.user_id IS DISTINCT FROM w.user_id
          OR o.action_type IS DISTINCT FROM CASE r.reason WHEN 'shop.purchase' THEN 'shop_buy' ELSE 'shop_sell' END
          OR o.metadata ->> 'shop_account_id' IS DISTINCT FROM r.account_id::text) AS mismatched_shop_references,
        count(*) FILTER (WHERE (r.reason = 'shop.purchase' AND r.amount >= 0) OR (r.reason = 'shop.sale' AND r.amount <= 0)) AS invalid_shop_directions
      FROM receipts r
        LEFT JOIN world_action_offers o ON o.id = r.offer_id
        LEFT JOIN shop_accounts a ON a.id = r.account_id
        LEFT JOIN characters c ON c.id = o.character_id
        LEFT JOIN currency_wallets w ON w.id = r.currency_wallet_id
    SQL
    invalid = counts.select { |_key, value| value.to_i.positive? }
    return if invalid.empty?

    raise ActiveRecord::MigrationError,
      "Currency hardening preflight failed: #{invalid.to_json}. Historical rows were not changed."
  end

  def safe_reference(key)
    <<~SQL.squish
      CASE WHEN jsonb_typeof(metadata -> '#{key}') = 'number'
        AND metadata ->> '#{key}' ~ '^[1-9][0-9]{0,18}$'
      THEN CASE WHEN (metadata ->> '#{key}')::numeric <= 9223372036854775807
        THEN (metadata ->> '#{key}')::bigint END
      END
    SQL
  end
end
