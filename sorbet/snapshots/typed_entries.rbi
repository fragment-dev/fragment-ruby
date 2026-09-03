# DO NOT EDIT MANUALLY
# Snapshot of the RBI that `bundle exec tapioca dsl` generates for the typed
# Ledger Entry payloads `FragmentClient::TypedEntries.load` builds at load
# time. Regenerate with `bundle exec rake snapshot`.
#
# In this repository the payloads come from test/fixtures/snapshot_entries.graphql,
# a synthetic Schema shaped to exercise every branch of the derivation. The
# entry types below are not real Fragment entry types -- they exist so that
# `test/snapshot_test.rb` has a reviewable diff and `srb tc` has something to
# check. In your own application the equivalent file lands in
# `sorbet/rbi/dsl/`, generated from your Schema's operations.

# typed: true

class FragmentClient
  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::AddLedgerEntry) }
  def add_ledger_entry(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::AddLedgerEntryRuntime) }
  def add_ledger_entry_runtime(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::CreateCustomCurrency) }
  def create_custom_currency(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::CreateCustomLink) }
  def create_custom_link(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::CreateLedger) }
  def create_ledger(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::CreatePayment) }
  def create_payment(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::DeleteCustomTxs) }
  def delete_custom_txs(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::DeleteLedger) }
  def delete_ledger(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::DeleteSchema) }
  def delete_schema(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetAccountDataMigrations) }
  def get_account_data_migrations(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetEntriesToMigrateForLedgerAccountDataMigration) }
  def get_entries_to_migrate_for_ledger_account_data_migration(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetEntriesToMigrateForLedgerEntryDataMigration) }
  def get_entries_to_migrate_for_ledger_entry_data_migration(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetEntryDataMigrations) }
  def get_entry_data_migrations(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetLedger) }
  def get_ledger(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetLedgerAccountBalance) }
  def get_ledger_account_balance(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetLedgerAccountLines) }
  def get_ledger_account_lines(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetLedgerEntry) }
  def get_ledger_entry(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetSchema) }
  def get_schema(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::GetWorkspace) }
  def get_workspace(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ListLedgerAccountBalances) }
  def list_ledger_account_balances(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ListLedgerAccounts) }
  def list_ledger_accounts(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ListLedgerEntries) }
  def list_ledger_entries(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ListLedgerEntryGroupBalances) }
  def list_ledger_entry_group_balances(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ListMultiCurrencyLedgerAccountBalances) }
  def list_multi_currency_ledger_account_balances(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::MigrateLedgerEntry) }
  def migrate_ledger_entry(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ReconcileTx) }
  def reconcile_tx(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ReconcileTxRuntime) }
  def reconcile_tx_runtime(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::ReverseLedgerEntry) }
  def reverse_ledger_entry(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::StoreSchema) }
  def store_schema(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::SyncCustomAccounts) }
  def sync_custom_accounts(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::SyncCustomTxs) }
  def sync_custom_txs(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::UpdateLedger) }
  def update_ledger(variables); end

  sig { params(variables: T::Hash[Symbol, T.untyped]).returns(::FragmentClient::Responses::UpdateLedgerEntry) }
  def update_ledger_entry(variables); end
end

module FragmentClient::Responses
  class AddLedgerEntries
    sig { returns(T.nilable(FragmentClient::Responses::AddLedgerEntries::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `addLedgerEntries`: AddLedgerEntriesResponse!
      sig { returns(AddLedgerEntries) }
      def add_ledger_entries; end

      class AddLedgerEntries
        sig { returns(::String) }
        def __typename; end

        # `results`: [AddLedgerEntryResult!]!
        sig { returns(T.nilable(T::Array[Results])) }
        def results; end

        class Results
          # `isIkReplay`: Boolean!
          sig { returns(T::Boolean) }
          def is_ik_replay; end

          # `entry`: LedgerEntry!
          sig { returns(Entry) }
          def entry; end

          class Entry
            # `type`: SafeString
            sig { returns(T.nilable(::String)) }
            def type; end

            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `ik`: String!
            sig { returns(::String) }
            def ik; end

            # `posted`: DateTime!
            sig { returns(::String) }
            def posted; end

            # `created`: DateTime!
            sig { returns(::String) }
            def created; end
          end

          # `lines`: [LedgerLine!]!
          sig { returns(T::Array[Lines]) }
          def lines; end

          class Lines
            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `amount`: Int96!
            sig { returns(::String) }
            def amount; end

            # `account`: LedgerAccount!
            sig { returns(Account) }
            def account; end

            class Account
              # `path`: String!
              sig { returns(::String) }
              def path; end
            end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end

        # `errors`: [AddLedgerEntryError!]!
        sig { returns(T.nilable(T::Array[Errors])) }
        def errors; end

        class Errors
          # `ik`: SafeString!
          sig { returns(::String) }
          def ik; end

          # `code`: String!
          sig { returns(::String) }
          def code; end

          # `message`: String!
          sig { returns(::String) }
          def message; end

          # `retryable`: Boolean!
          sig { returns(T::Boolean) }
          def retryable; end
        end
      end
    end
  end

  class AddLedgerEntry
    sig { returns(T.nilable(FragmentClient::Responses::AddLedgerEntry::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `addLedgerEntry`: AddLedgerEntryResponse!
      sig { returns(AddLedgerEntry) }
      def add_ledger_entry; end

      class AddLedgerEntry
        sig { returns(::String) }
        def __typename; end

        # `isIkReplay`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def is_ik_replay; end

        # `entry`: LedgerEntry!
        sig { returns(T.nilable(Entry)) }
        def entry; end

        class Entry
          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end
        end

        # `lines`: [LedgerLine!]!
        sig { returns(T.nilable(T::Array[Lines])) }
        def lines; end

        class Lines
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `amount`: Int96!
          sig { returns(::String) }
          def amount; end

          # `account`: LedgerAccount!
          sig { returns(Account) }
          def account; end

          class Account
            # `path`: String!
            sig { returns(::String) }
            def path; end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class AddLedgerEntryRuntime
    sig { returns(T.nilable(FragmentClient::Responses::AddLedgerEntryRuntime::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `addLedgerEntry`: AddLedgerEntryResponse!
      sig { returns(AddLedgerEntry) }
      def add_ledger_entry; end

      class AddLedgerEntry
        sig { returns(::String) }
        def __typename; end

        # `isIkReplay`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def is_ik_replay; end

        # `entry`: LedgerEntry!
        sig { returns(T.nilable(Entry)) }
        def entry; end

        class Entry
          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end
        end

        # `lines`: [LedgerLine!]!
        sig { returns(T.nilable(T::Array[Lines])) }
        def lines; end

        class Lines
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `amount`: Int96!
          sig { returns(::String) }
          def amount; end

          # `account`: LedgerAccount!
          sig { returns(Account) }
          def account; end

          class Account
            # `path`: String!
            sig { returns(::String) }
            def path; end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class CreateCustomCurrency
    sig { returns(T.nilable(FragmentClient::Responses::CreateCustomCurrency::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `createCustomCurrency`: CreateCustomCurrencyResponse!
      sig { returns(CreateCustomCurrency) }
      def create_custom_currency; end

      class CreateCustomCurrency
        # `customCurrency`: Currency!
        sig { returns(T.nilable(CustomCurrency)) }
        def custom_currency; end

        class CustomCurrency
          # `code`: CurrencyCode!
          sig { returns(T.untyped) }
          def code; end

          # `customCurrencyId`: SafeString
          sig { returns(T.nilable(::String)) }
          def custom_currency_id; end

          # `precision`: Int!
          sig { returns(::Integer) }
          def precision; end

          # `name`: String!
          sig { returns(::String) }
          def name; end

          # `customCode`: String
          sig { returns(T.nilable(::String)) }
          def custom_code; end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class CreateCustomLink
    sig { returns(T.nilable(FragmentClient::Responses::CreateCustomLink::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `createCustomLink`: CreateCustomLinkResponse!
      sig { returns(CreateCustomLink) }
      def create_custom_link; end

      class CreateCustomLink
        sig { returns(::String) }
        def __typename; end

        # `link`: CustomLink!
        sig { returns(T.nilable(Link)) }
        def link; end

        class Link
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `name`: String!
          sig { returns(::String) }
          def name; end

          # `created`: String!
          sig { returns(::String) }
          def created; end
        end

        # `isIkReplay`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def is_ik_replay; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class CreateLedger
    sig { returns(T.nilable(FragmentClient::Responses::CreateLedger::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `createLedger`: CreateLedgerResponse!
      sig { returns(CreateLedger) }
      def create_ledger; end

      class CreateLedger
        sig { returns(::String) }
        def __typename; end

        # `ledger`: Ledger!
        sig { returns(T.nilable(Ledger)) }
        def ledger; end

        class Ledger
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: SafeString!
          sig { returns(::String) }
          def ik; end

          # `name`: String!
          sig { returns(::String) }
          def name; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `schema`: Schema
          sig { returns(T.nilable(Schema)) }
          def schema; end

          class Schema
            # `key`: SafeString!
            sig { returns(::String) }
            def key; end
          end
        end

        # `isIkReplay`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def is_ik_replay; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class CreatePayment
    sig { returns(T.nilable(FragmentClient::Responses::CreatePayment::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `createPayment`: CreatePaymentResponse!
      sig { returns(CreatePayment) }
      def create_payment; end

      class CreatePayment
        sig { returns(::String) }
        def __typename; end

        # `clientSecret`: String!
        sig { returns(T.nilable(::String)) }
        def client_secret; end

        # `status`: PaymentStatus!
        sig { returns(T.untyped) }
        def status; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class DeleteCustomTxs
    sig { returns(T.nilable(FragmentClient::Responses::DeleteCustomTxs::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `deleteCustomTxs`: DeleteCustomTxsResponse!
      sig { returns(DeleteCustomTxs) }
      def delete_custom_txs; end

      class DeleteCustomTxs
        sig { returns(::String) }
        def __typename; end

        # `txs`: [DeletedCustomTx!]!
        sig { returns(T.nilable(T::Array[Txs])) }
        def txs; end

        class Txs
          # `tx`: Tx!
          sig { returns(Tx) }
          def tx; end

          class Tx
            # `linkId`: ID!
            sig { returns(::String) }
            def link_id; end

            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `externalId`: ID!
            sig { returns(::String) }
            def external_id; end

            # `externalAccountId`: ID!
            sig { returns(::String) }
            def external_account_id; end

            # `amount`: Int96!
            sig { returns(::String) }
            def amount; end

            # `description`: String!
            sig { returns(::String) }
            def description; end

            # `posted`: DateTime!
            sig { returns(::String) }
            def posted; end

            # `deletedAt`: DateTime
            sig { returns(T.nilable(::String)) }
            def deleted_at; end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class DeleteLedger
    sig { returns(T.nilable(FragmentClient::Responses::DeleteLedger::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `deleteLedger`: DeleteLedgerResponse!
      sig { returns(DeleteLedger) }
      def delete_ledger; end

      class DeleteLedger
        sig { returns(::String) }
        def __typename; end

        # `success`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def success; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class DeleteSchema
    sig { returns(T.nilable(FragmentClient::Responses::DeleteSchema::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `deleteSchema`: DeleteSchemaResponse!
      sig { returns(DeleteSchema) }
      def delete_schema; end

      class DeleteSchema
        sig { returns(::String) }
        def __typename; end

        # `success`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def success; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class GetAccountDataMigrations
    sig { returns(T.nilable(FragmentClient::Responses::GetAccountDataMigrations::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `ledgerAccountDataMigrations`: LedgerAccountDataMigrationConnection!
        sig { returns(LedgerAccountDataMigrations) }
        def ledger_account_data_migrations; end

        class LedgerAccountDataMigrations
          # `nodes`: [LedgerAccountDataMigration!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `accountPath`: String!
            sig { returns(::String) }
            def account_path; end

            # `status`: LedgerDataMigrationStatus!
            sig { returns(T.untyped) }
            def status; end

            # `currentMigration`: LedgerDataMigrationHistoryEntry
            sig { returns(T.nilable(CurrentMigration)) }
            def current_migration; end

            class CurrentMigration
              # `schemaVersion`: Int!
              sig { returns(::Integer) }
              def schema_version; end

              # `status`: LedgerDataMigrationStatus!
              sig { returns(T.untyped) }
              def status; end
            end

            # `ledgerEntries`: LedgerEntriesConnection!
            sig { returns(LedgerEntries) }
            def ledger_entries; end

            class LedgerEntries
              # `nodes`: [LedgerEntry!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `id`: ID!
                sig { returns(::String) }
                def id; end

                # `type`: SafeString
                sig { returns(T.nilable(::String)) }
                def type; end

                # `posted`: DateTime!
                sig { returns(::String) }
                def posted; end

                # `parameters`: Parameters
                sig { returns(T.untyped) }
                def parameters; end
              end

              # `pageInfo`: PageInfo!
              sig { returns(PageInfo) }
              def page_info; end

              class PageInfo
                # `hasNextPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_next_page; end

                # `endCursor`: String
                sig { returns(T.nilable(::String)) }
                def end_cursor; end

                # `hasPreviousPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_previous_page; end

                # `startCursor`: String
                sig { returns(T.nilable(::String)) }
                def start_cursor; end
              end
            end

            # `history`: LedgerDataMigrationHistoryConnection!
            sig { returns(History) }
            def history; end

            class History
              # `nodes`: [LedgerDataMigrationHistoryEntry!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `schemaVersion`: Int!
                sig { returns(::Integer) }
                def schema_version; end

                # `status`: LedgerDataMigrationStatus!
                sig { returns(T.untyped) }
                def status; end
              end

              # `pageInfo`: PageInfo!
              sig { returns(PageInfo) }
              def page_info; end

              class PageInfo
                # `hasNextPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_next_page; end

                # `endCursor`: String
                sig { returns(T.nilable(::String)) }
                def end_cursor; end

                # `hasPreviousPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_previous_page; end

                # `startCursor`: String
                sig { returns(T.nilable(::String)) }
                def start_cursor; end
              end
            end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class GetEntriesToMigrateForLedgerAccountDataMigration
    sig { returns(T.nilable(FragmentClient::Responses::GetEntriesToMigrateForLedgerAccountDataMigration::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `ledgerAccountDataMigrations`: LedgerAccountDataMigrationConnection!
        sig { returns(LedgerAccountDataMigrations) }
        def ledger_account_data_migrations; end

        class LedgerAccountDataMigrations
          # `nodes`: [LedgerAccountDataMigration!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `ledgerEntries`: LedgerEntriesConnection!
            sig { returns(LedgerEntries) }
            def ledger_entries; end

            class LedgerEntries
              # `nodes`: [LedgerEntry!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `id`: ID!
                sig { returns(::String) }
                def id; end

                # `ik`: String!
                sig { returns(::String) }
                def ik; end

                # `type`: SafeString
                sig { returns(T.nilable(::String)) }
                def type; end

                # `typeVersion`: Int
                sig { returns(T.nilable(::Integer)) }
                def type_version; end

                # `description`: String
                sig { returns(T.nilable(::String)) }
                def description; end

                # `posted`: DateTime!
                sig { returns(::String) }
                def posted; end

                # `created`: DateTime!
                sig { returns(::String) }
                def created; end

                # `parameters`: Parameters
                sig { returns(T.untyped) }
                def parameters; end

                # `lines`: LedgerLinesConnection!
                sig { returns(Lines) }
                def lines; end

                class Lines
                  # `nodes`: [LedgerLine!]!
                  sig { returns(T::Array[Nodes]) }
                  def nodes; end

                  class Nodes
                    # `id`: ID!
                    sig { returns(::String) }
                    def id; end

                    # `amount`: Int96!
                    sig { returns(::String) }
                    def amount; end

                    # `account`: LedgerAccount!
                    sig { returns(Account) }
                    def account; end

                    class Account
                      # `path`: String!
                      sig { returns(::String) }
                      def path; end
                    end
                  end
                end
              end

              # `pageInfo`: PageInfo!
              sig { returns(PageInfo) }
              def page_info; end

              class PageInfo
                # `hasNextPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_next_page; end

                # `endCursor`: String
                sig { returns(T.nilable(::String)) }
                def end_cursor; end

                # `hasPreviousPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_previous_page; end

                # `startCursor`: String
                sig { returns(T.nilable(::String)) }
                def start_cursor; end
              end
            end
          end
        end
      end
    end
  end

  class GetEntriesToMigrateForLedgerEntryDataMigration
    sig { returns(T.nilable(FragmentClient::Responses::GetEntriesToMigrateForLedgerEntryDataMigration::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `ledgerEntryDataMigrations`: LedgerEntryDataMigrationConnection!
        sig { returns(LedgerEntryDataMigrations) }
        def ledger_entry_data_migrations; end

        class LedgerEntryDataMigrations
          # `nodes`: [LedgerEntryDataMigration!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `ledgerEntries`: LedgerEntriesConnection!
            sig { returns(LedgerEntries) }
            def ledger_entries; end

            class LedgerEntries
              # `nodes`: [LedgerEntry!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `id`: ID!
                sig { returns(::String) }
                def id; end

                # `ik`: String!
                sig { returns(::String) }
                def ik; end

                # `type`: SafeString
                sig { returns(T.nilable(::String)) }
                def type; end

                # `typeVersion`: Int
                sig { returns(T.nilable(::Integer)) }
                def type_version; end

                # `description`: String
                sig { returns(T.nilable(::String)) }
                def description; end

                # `posted`: DateTime!
                sig { returns(::String) }
                def posted; end

                # `created`: DateTime!
                sig { returns(::String) }
                def created; end

                # `parameters`: Parameters
                sig { returns(T.untyped) }
                def parameters; end

                # `lines`: LedgerLinesConnection!
                sig { returns(Lines) }
                def lines; end

                class Lines
                  # `nodes`: [LedgerLine!]!
                  sig { returns(T::Array[Nodes]) }
                  def nodes; end

                  class Nodes
                    # `id`: ID!
                    sig { returns(::String) }
                    def id; end

                    # `amount`: Int96!
                    sig { returns(::String) }
                    def amount; end

                    # `account`: LedgerAccount!
                    sig { returns(Account) }
                    def account; end

                    class Account
                      # `path`: String!
                      sig { returns(::String) }
                      def path; end
                    end
                  end
                end
              end

              # `pageInfo`: PageInfo!
              sig { returns(PageInfo) }
              def page_info; end

              class PageInfo
                # `hasNextPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_next_page; end

                # `endCursor`: String
                sig { returns(T.nilable(::String)) }
                def end_cursor; end

                # `hasPreviousPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_previous_page; end

                # `startCursor`: String
                sig { returns(T.nilable(::String)) }
                def start_cursor; end
              end
            end
          end
        end
      end
    end
  end

  class GetEntryDataMigrations
    sig { returns(T.nilable(FragmentClient::Responses::GetEntryDataMigrations::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `ledgerEntryDataMigrations`: LedgerEntryDataMigrationConnection!
        sig { returns(LedgerEntryDataMigrations) }
        def ledger_entry_data_migrations; end

        class LedgerEntryDataMigrations
          # `nodes`: [LedgerEntryDataMigration!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `entryType`: SafeString!
            sig { returns(::String) }
            def entry_type; end

            # `typeVersion`: Int!
            sig { returns(::Integer) }
            def type_version; end

            # `status`: LedgerDataMigrationStatus!
            sig { returns(T.untyped) }
            def status; end

            # `currentMigration`: LedgerDataMigrationHistoryEntry
            sig { returns(T.nilable(CurrentMigration)) }
            def current_migration; end

            class CurrentMigration
              # `schemaVersion`: Int!
              sig { returns(::Integer) }
              def schema_version; end

              # `status`: LedgerDataMigrationStatus!
              sig { returns(T.untyped) }
              def status; end
            end

            # `ledgerEntries`: LedgerEntriesConnection!
            sig { returns(LedgerEntries) }
            def ledger_entries; end

            class LedgerEntries
              # `nodes`: [LedgerEntry!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `id`: ID!
                sig { returns(::String) }
                def id; end

                # `type`: SafeString
                sig { returns(T.nilable(::String)) }
                def type; end

                # `posted`: DateTime!
                sig { returns(::String) }
                def posted; end

                # `parameters`: Parameters
                sig { returns(T.untyped) }
                def parameters; end
              end

              # `pageInfo`: PageInfo!
              sig { returns(PageInfo) }
              def page_info; end

              class PageInfo
                # `hasNextPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_next_page; end

                # `endCursor`: String
                sig { returns(T.nilable(::String)) }
                def end_cursor; end

                # `hasPreviousPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_previous_page; end

                # `startCursor`: String
                sig { returns(T.nilable(::String)) }
                def start_cursor; end
              end
            end

            # `history`: LedgerDataMigrationHistoryConnection!
            sig { returns(History) }
            def history; end

            class History
              # `nodes`: [LedgerDataMigrationHistoryEntry!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `schemaVersion`: Int!
                sig { returns(::Integer) }
                def schema_version; end

                # `status`: LedgerDataMigrationStatus!
                sig { returns(T.untyped) }
                def status; end
              end

              # `pageInfo`: PageInfo!
              sig { returns(PageInfo) }
              def page_info; end

              class PageInfo
                # `hasNextPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_next_page; end

                # `endCursor`: String
                sig { returns(T.nilable(::String)) }
                def end_cursor; end

                # `hasPreviousPage`: Boolean!
                sig { returns(T::Boolean) }
                def has_previous_page; end

                # `startCursor`: String
                sig { returns(T.nilable(::String)) }
                def start_cursor; end
              end
            end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class GetLedger
    sig { returns(T.nilable(FragmentClient::Responses::GetLedger::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `ik`: SafeString!
        sig { returns(::String) }
        def ik; end

        # `name`: String!
        sig { returns(::String) }
        def name; end

        # `created`: DateTime!
        sig { returns(::String) }
        def created; end

        # `balanceUTCOffset`: UTCOffset!
        sig { returns(::String) }
        def balance_utc_offset; end
      end
    end
  end

  class GetLedgerAccountBalance
    sig { returns(T.nilable(FragmentClient::Responses::GetLedgerAccountBalance::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledgerAccount`: LedgerAccount
      sig { returns(T.nilable(LedgerAccount)) }
      def ledger_account; end

      class LedgerAccount
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `path`: String!
        sig { returns(::String) }
        def path; end

        # `balance`: Int96!
        sig { returns(::String) }
        def balance; end
      end
    end
  end

  class GetLedgerAccountLines
    sig { returns(T.nilable(FragmentClient::Responses::GetLedgerAccountLines::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledgerAccount`: LedgerAccount
      sig { returns(T.nilable(LedgerAccount)) }
      def ledger_account; end

      class LedgerAccount
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `path`: String!
        sig { returns(::String) }
        def path; end

        # `lines`: LedgerLinesConnection!
        sig { returns(Lines) }
        def lines; end

        class Lines
          # `nodes`: [LedgerLine!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `posted`: DateTime
            sig { returns(T.nilable(::String)) }
            def posted; end

            # `created`: DateTime
            sig { returns(T.nilable(::String)) }
            def created; end

            # `amount`: Int96!
            sig { returns(::String) }
            def amount; end

            # `description`: String
            sig { returns(T.nilable(::String)) }
            def description; end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class GetLedgerEntry
    sig { returns(T.nilable(FragmentClient::Responses::GetLedgerEntry::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledgerEntry`: LedgerEntry
      sig { returns(T.nilable(LedgerEntry)) }
      def ledger_entry; end

      class LedgerEntry
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `ik`: String!
        sig { returns(::String) }
        def ik; end

        # `posted`: DateTime!
        sig { returns(::String) }
        def posted; end

        # `created`: DateTime!
        sig { returns(::String) }
        def created; end

        # `description`: String
        sig { returns(T.nilable(::String)) }
        def description; end

        # `lines`: LedgerLinesConnection!
        sig { returns(Lines) }
        def lines; end

        class Lines
          # `nodes`: [LedgerLine!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `amount`: Int96!
            sig { returns(::String) }
            def amount; end

            # `account`: LedgerAccount!
            sig { returns(Account) }
            def account; end

            class Account
              # `path`: String!
              sig { returns(::String) }
              def path; end
            end
          end
        end
      end
    end
  end

  class GetSchema
    sig { returns(T.nilable(FragmentClient::Responses::GetSchema::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `schema`: Schema
      sig { returns(T.nilable(Schema)) }
      def schema; end

      class Schema
        # `key`: SafeString!
        sig { returns(::String) }
        def key; end

        # `name`: String!
        sig { returns(::String) }
        def name; end

        # `version`: SchemaVersion!
        sig { returns(Version) }
        def version; end

        class Version
          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `version`: Int!
          sig { returns(::Integer) }
          def version; end

          # `json`: JSON!
          sig { returns(T.untyped) }
          def json; end
        end
      end
    end
  end

  class GetWorkspace
    sig { returns(T.nilable(FragmentClient::Responses::GetWorkspace::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `workspace`: Workspace!
      sig { returns(Workspace) }
      def workspace; end

      class Workspace
        # `id`: String!
        sig { returns(::String) }
        def id; end

        # `name`: String!
        sig { returns(::String) }
        def name; end
      end
    end
  end

  class ListLedgerAccountBalances
    sig { returns(T.nilable(FragmentClient::Responses::ListLedgerAccountBalances::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `ik`: SafeString!
        sig { returns(::String) }
        def ik; end

        # `name`: String!
        sig { returns(::String) }
        def name; end

        # `created`: DateTime!
        sig { returns(::String) }
        def created; end

        # `ledgerAccounts`: LedgerAccountsConnection!
        sig { returns(LedgerAccounts) }
        def ledger_accounts; end

        class LedgerAccounts
          # `nodes`: [LedgerAccount!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `path`: String!
            sig { returns(::String) }
            def path; end

            # `name`: String
            sig { returns(T.nilable(::String)) }
            def name; end

            # `type`: LedgerAccountTypes!
            sig { returns(T.untyped) }
            def type; end

            # `created`: DateTime!
            sig { returns(::String) }
            def created; end

            # `ownBalance`: Int96!
            sig { returns(::String) }
            def own_balance; end

            # `childBalance`: Int96!
            sig { returns(::String) }
            def child_balance; end

            # `balance`: Int96!
            sig { returns(::String) }
            def balance; end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class ListLedgerAccounts
    sig { returns(T.nilable(FragmentClient::Responses::ListLedgerAccounts::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `ik`: SafeString!
        sig { returns(::String) }
        def ik; end

        # `name`: String!
        sig { returns(::String) }
        def name; end

        # `created`: DateTime!
        sig { returns(::String) }
        def created; end

        # `ledgerAccounts`: LedgerAccountsConnection!
        sig { returns(LedgerAccounts) }
        def ledger_accounts; end

        class LedgerAccounts
          # `nodes`: [LedgerAccount!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `path`: String!
            sig { returns(::String) }
            def path; end

            # `name`: String
            sig { returns(T.nilable(::String)) }
            def name; end

            # `type`: LedgerAccountTypes!
            sig { returns(T.untyped) }
            def type; end

            # `created`: DateTime!
            sig { returns(::String) }
            def created; end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class ListLedgerEntries
    sig { returns(T.nilable(FragmentClient::Responses::ListLedgerEntries::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `ledgerEntries`: LedgerEntriesConnection!
        sig { returns(LedgerEntries) }
        def ledger_entries; end

        class LedgerEntries
          # `nodes`: [LedgerEntry!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `ik`: String!
            sig { returns(::String) }
            def ik; end

            # `type`: SafeString
            sig { returns(T.nilable(::String)) }
            def type; end

            # `posted`: DateTime!
            sig { returns(::String) }
            def posted; end

            # `lines`: LedgerLinesConnection!
            sig { returns(Lines) }
            def lines; end

            class Lines
              # `nodes`: [LedgerLine!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `amount`: Int96!
                sig { returns(::String) }
                def amount; end

                # `account`: LedgerAccount!
                sig { returns(Account) }
                def account; end

                class Account
                  # `path`: String!
                  sig { returns(::String) }
                  def path; end
                end
              end
            end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class ListLedgerEntryGroupBalances
    sig { returns(T.nilable(FragmentClient::Responses::ListLedgerEntryGroupBalances::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledgerEntryGroup`: LedgerEntryGroup
      sig { returns(T.nilable(LedgerEntryGroup)) }
      def ledger_entry_group; end

      class LedgerEntryGroup
        # `key`: SafeString!
        sig { returns(::String) }
        def key; end

        # `value`: SafeString!
        sig { returns(::String) }
        def value; end

        # `created`: DateTime
        sig { returns(T.nilable(::String)) }
        def created; end

        # `balances`: LedgerEntryGroupBalanceConnection!
        sig { returns(Balances) }
        def balances; end

        class Balances
          # `nodes`: [LedgerEntryGroupBalance!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `account`: LedgerAccount!
            sig { returns(Account) }
            def account; end

            class Account
              # `path`: String!
              sig { returns(::String) }
              def path; end
            end

            # `currency`: Currency!
            sig { returns(Currency) }
            def currency; end

            class Currency
              # `code`: CurrencyCode!
              sig { returns(T.untyped) }
              def code; end

              # `customCurrencyId`: SafeString
              sig { returns(T.nilable(::String)) }
              def custom_currency_id; end
            end

            # `ownBalance`: Int96!
            sig { returns(::String) }
            def own_balance; end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class ListMultiCurrencyLedgerAccountBalances
    sig { returns(T.nilable(FragmentClient::Responses::ListMultiCurrencyLedgerAccountBalances::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `ledger`: Ledger
      sig { returns(T.nilable(Ledger)) }
      def ledger; end

      class Ledger
        # `id`: ID!
        sig { returns(::String) }
        def id; end

        # `ik`: SafeString!
        sig { returns(::String) }
        def ik; end

        # `name`: String!
        sig { returns(::String) }
        def name; end

        # `created`: DateTime!
        sig { returns(::String) }
        def created; end

        # `ledgerAccounts`: LedgerAccountsConnection!
        sig { returns(LedgerAccounts) }
        def ledger_accounts; end

        class LedgerAccounts
          # `nodes`: [LedgerAccount!]!
          sig { returns(T::Array[Nodes]) }
          def nodes; end

          class Nodes
            # `id`: ID!
            sig { returns(::String) }
            def id; end

            # `path`: String!
            sig { returns(::String) }
            def path; end

            # `name`: String
            sig { returns(T.nilable(::String)) }
            def name; end

            # `type`: LedgerAccountTypes!
            sig { returns(T.untyped) }
            def type; end

            # `created`: DateTime!
            sig { returns(::String) }
            def created; end

            # `ownBalances`: CurrencyAmountConnection!
            sig { returns(OwnBalances) }
            def own_balances; end

            class OwnBalances
              # `nodes`: [CurrencyAmount!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `currency`: Currency!
                sig { returns(Currency) }
                def currency; end

                class Currency
                  # `code`: CurrencyCode!
                  sig { returns(T.untyped) }
                  def code; end

                  # `customCurrencyId`: SafeString
                  sig { returns(T.nilable(::String)) }
                  def custom_currency_id; end
                end

                # `amount`: Int96!
                sig { returns(::String) }
                def amount; end
              end
            end

            # `childBalances`: CurrencyAmountConnection!
            sig { returns(ChildBalances) }
            def child_balances; end

            class ChildBalances
              # `nodes`: [CurrencyAmount!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `currency`: Currency!
                sig { returns(Currency) }
                def currency; end

                class Currency
                  # `code`: CurrencyCode!
                  sig { returns(T.untyped) }
                  def code; end

                  # `customCurrencyId`: SafeString
                  sig { returns(T.nilable(::String)) }
                  def custom_currency_id; end
                end

                # `amount`: Int96!
                sig { returns(::String) }
                def amount; end
              end
            end

            # `balances`: CurrencyAmountConnection!
            sig { returns(Balances) }
            def balances; end

            class Balances
              # `nodes`: [CurrencyAmount!]!
              sig { returns(T::Array[Nodes]) }
              def nodes; end

              class Nodes
                # `currency`: Currency!
                sig { returns(Currency) }
                def currency; end

                class Currency
                  # `code`: CurrencyCode!
                  sig { returns(T.untyped) }
                  def code; end

                  # `customCurrencyId`: SafeString
                  sig { returns(T.nilable(::String)) }
                  def custom_currency_id; end
                end

                # `amount`: Int96!
                sig { returns(::String) }
                def amount; end
              end
            end
          end

          # `pageInfo`: PageInfo!
          sig { returns(PageInfo) }
          def page_info; end

          class PageInfo
            # `hasNextPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_next_page; end

            # `endCursor`: String
            sig { returns(T.nilable(::String)) }
            def end_cursor; end

            # `hasPreviousPage`: Boolean!
            sig { returns(T::Boolean) }
            def has_previous_page; end

            # `startCursor`: String
            sig { returns(T.nilable(::String)) }
            def start_cursor; end
          end
        end
      end
    end
  end

  class MigrateLedgerEntry
    sig { returns(T.nilable(FragmentClient::Responses::MigrateLedgerEntry::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `migrateLedgerEntry`: MigrateLedgerEntryResponse!
      sig { returns(MigrateLedgerEntry) }
      def migrate_ledger_entry; end

      class MigrateLedgerEntry
        sig { returns(::String) }
        def __typename; end

        # `reversingLedgerEntry`: LedgerEntry!
        sig { returns(T.nilable(ReversingLedgerEntry)) }
        def reversing_ledger_entry; end

        class ReversingLedgerEntry
          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end

          # `reversedAt`: DateTime
          sig { returns(T.nilable(::String)) }
          def reversed_at; end

          # `hidden`: Boolean!
          sig { returns(T::Boolean) }
          def hidden; end

          # `lines`: LedgerLinesConnection!
          sig { returns(Lines) }
          def lines; end

          class Lines
            # `nodes`: [LedgerLine!]!
            sig { returns(T::Array[Nodes]) }
            def nodes; end

            class Nodes
              # `id`: ID!
              sig { returns(::String) }
              def id; end

              # `amount`: Int96!
              sig { returns(::String) }
              def amount; end

              # `account`: LedgerAccount!
              sig { returns(Account) }
              def account; end

              class Account
                # `path`: String!
                sig { returns(::String) }
                def path; end
              end
            end
          end
        end

        # `reversedLedgerEntry`: LedgerEntry!
        sig { returns(T.nilable(ReversedLedgerEntry)) }
        def reversed_ledger_entry; end

        class ReversedLedgerEntry
          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end

          # `reversedAt`: DateTime
          sig { returns(T.nilable(::String)) }
          def reversed_at; end

          # `hidden`: Boolean!
          sig { returns(T::Boolean) }
          def hidden; end

          # `lines`: LedgerLinesConnection!
          sig { returns(Lines) }
          def lines; end

          class Lines
            # `nodes`: [LedgerLine!]!
            sig { returns(T::Array[Nodes]) }
            def nodes; end

            class Nodes
              # `id`: ID!
              sig { returns(::String) }
              def id; end

              # `amount`: Int96!
              sig { returns(::String) }
              def amount; end

              # `account`: LedgerAccount!
              sig { returns(Account) }
              def account; end

              class Account
                # `path`: String!
                sig { returns(::String) }
                def path; end
              end
            end
          end
        end

        # `newLedgerEntry`: LedgerEntry!
        sig { returns(T.nilable(NewLedgerEntry)) }
        def new_ledger_entry; end

        class NewLedgerEntry
          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end

          # `reversedAt`: DateTime
          sig { returns(T.nilable(::String)) }
          def reversed_at; end

          # `hidden`: Boolean!
          sig { returns(T::Boolean) }
          def hidden; end

          # `lines`: LedgerLinesConnection!
          sig { returns(Lines) }
          def lines; end

          class Lines
            # `nodes`: [LedgerLine!]!
            sig { returns(T::Array[Nodes]) }
            def nodes; end

            class Nodes
              # `id`: ID!
              sig { returns(::String) }
              def id; end

              # `amount`: Int96!
              sig { returns(::String) }
              def amount; end

              # `account`: LedgerAccount!
              sig { returns(Account) }
              def account; end

              class Account
                # `path`: String!
                sig { returns(::String) }
                def path; end
              end
            end
          end
        end

        # `isIkReplay`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def is_ik_replay; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class ReconcileTx
    sig { returns(T.nilable(FragmentClient::Responses::ReconcileTx::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `reconcileTx`: ReconcileTxResponse!
      sig { returns(ReconcileTx) }
      def reconcile_tx; end

      class ReconcileTx
        sig { returns(::String) }
        def __typename; end

        # `entry`: LedgerEntry!
        sig { returns(T.nilable(Entry)) }
        def entry; end

        class Entry
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `date`: Date!
          sig { returns(::String) }
          def date; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end
        end

        # `lines`: [LedgerLine!]!
        sig { returns(T.nilable(T::Array[Lines])) }
        def lines; end

        class Lines
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `amount`: Int96!
          sig { returns(::String) }
          def amount; end

          # `account`: LedgerAccount!
          sig { returns(Account) }
          def account; end

          class Account
            # `path`: String!
            sig { returns(::String) }
            def path; end
          end

          # `externalTxId`: String
          sig { returns(T.nilable(::String)) }
          def external_tx_id; end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class ReconcileTxRuntime
    sig { returns(T.nilable(FragmentClient::Responses::ReconcileTxRuntime::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `reconcileTx`: ReconcileTxResponse!
      sig { returns(ReconcileTx) }
      def reconcile_tx; end

      class ReconcileTx
        sig { returns(::String) }
        def __typename; end

        # `entry`: LedgerEntry!
        sig { returns(T.nilable(Entry)) }
        def entry; end

        class Entry
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `date`: Date!
          sig { returns(::String) }
          def date; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end
        end

        # `lines`: [LedgerLine!]!
        sig { returns(T.nilable(T::Array[Lines])) }
        def lines; end

        class Lines
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `amount`: Int96!
          sig { returns(::String) }
          def amount; end

          # `account`: LedgerAccount!
          sig { returns(Account) }
          def account; end

          class Account
            # `path`: String!
            sig { returns(::String) }
            def path; end
          end

          # `externalTxId`: String
          sig { returns(T.nilable(::String)) }
          def external_tx_id; end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class ReverseLedgerEntry
    sig { returns(T.nilable(FragmentClient::Responses::ReverseLedgerEntry::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `reverseLedgerEntry`: ReverseLedgerEntryResponse!
      sig { returns(ReverseLedgerEntry) }
      def reverse_ledger_entry; end

      class ReverseLedgerEntry
        sig { returns(::String) }
        def __typename; end

        # `reversingLedgerEntry`: LedgerEntry!
        sig { returns(T.nilable(ReversingLedgerEntry)) }
        def reversing_ledger_entry; end

        class ReversingLedgerEntry
          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end

          # `hidden`: Boolean!
          sig { returns(T::Boolean) }
          def hidden; end

          # `lines`: LedgerLinesConnection!
          sig { returns(Lines) }
          def lines; end

          class Lines
            # `nodes`: [LedgerLine!]!
            sig { returns(T::Array[Nodes]) }
            def nodes; end

            class Nodes
              # `id`: ID!
              sig { returns(::String) }
              def id; end

              # `amount`: Int96!
              sig { returns(::String) }
              def amount; end

              # `account`: LedgerAccount!
              sig { returns(Account) }
              def account; end

              class Account
                # `path`: String!
                sig { returns(::String) }
                def path; end
              end
            end
          end
        end

        # `reversedLedgerEntry`: LedgerEntry!
        sig { returns(T.nilable(ReversedLedgerEntry)) }
        def reversed_ledger_entry; end

        class ReversedLedgerEntry
          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `type`: SafeString
          sig { returns(T.nilable(::String)) }
          def type; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end

          # `hidden`: Boolean!
          sig { returns(T::Boolean) }
          def hidden; end

          # `lines`: LedgerLinesConnection!
          sig { returns(Lines) }
          def lines; end

          class Lines
            # `nodes`: [LedgerLine!]!
            sig { returns(T::Array[Nodes]) }
            def nodes; end

            class Nodes
              # `id`: ID!
              sig { returns(::String) }
              def id; end

              # `amount`: Int96!
              sig { returns(::String) }
              def amount; end

              # `account`: LedgerAccount!
              sig { returns(Account) }
              def account; end

              class Account
                # `path`: String!
                sig { returns(::String) }
                def path; end
              end
            end
          end
        end

        # `isIkReplay`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def is_ik_replay; end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class StoreSchema
    sig { returns(T.nilable(FragmentClient::Responses::StoreSchema::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `storeSchema`: StoreSchemaResponse!
      sig { returns(StoreSchema) }
      def store_schema; end

      class StoreSchema
        sig { returns(::String) }
        def __typename; end

        # `schema`: Schema!
        sig { returns(T.nilable(Schema)) }
        def schema; end

        class Schema
          # `key`: SafeString!
          sig { returns(::String) }
          def key; end

          # `name`: String!
          sig { returns(::String) }
          def name; end

          # `version`: SchemaVersion!
          sig { returns(Version) }
          def version; end

          class Version
            # `created`: DateTime!
            sig { returns(::String) }
            def created; end

            # `version`: Int!
            sig { returns(::Integer) }
            def version; end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class SyncCustomAccounts
    sig { returns(T.nilable(FragmentClient::Responses::SyncCustomAccounts::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `syncCustomAccounts`: SyncCustomAccountsResponse!
      sig { returns(SyncCustomAccounts) }
      def sync_custom_accounts; end

      class SyncCustomAccounts
        sig { returns(::String) }
        def __typename; end

        # `accounts`: [ExternalAccount!]!
        sig { returns(T.nilable(T::Array[Accounts])) }
        def accounts; end

        class Accounts
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `externalId`: ID!
          sig { returns(::String) }
          def external_id; end

          # `name`: String!
          sig { returns(::String) }
          def name; end

          # `currency`: Currency
          sig { returns(T.nilable(Currency)) }
          def currency; end

          class Currency
            # `code`: CurrencyCode!
            sig { returns(T.untyped) }
            def code; end

            # `customCurrencyId`: SafeString
            sig { returns(T.nilable(::String)) }
            def custom_currency_id; end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class SyncCustomTxs
    sig { returns(T.nilable(FragmentClient::Responses::SyncCustomTxs::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `syncCustomTxs`: SyncCustomTxsResponse!
      sig { returns(SyncCustomTxs) }
      def sync_custom_txs; end

      class SyncCustomTxs
        sig { returns(::String) }
        def __typename; end

        # `txs`: [Tx!]!
        sig { returns(T.nilable(T::Array[Txs])) }
        def txs; end

        class Txs
          sig { returns(::String) }
          def __typename; end

          # `linkId`: ID!
          sig { returns(::String) }
          def link_id; end

          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `externalId`: ID!
          sig { returns(::String) }
          def external_id; end

          # `externalAccountId`: ID!
          sig { returns(::String) }
          def external_account_id; end

          # `amount`: Int96!
          sig { returns(::String) }
          def amount; end

          # `description`: String!
          sig { returns(::String) }
          def description; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class UpdateLedger
    sig { returns(T.nilable(FragmentClient::Responses::UpdateLedger::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `updateLedger`: UpdateLedgerResponse!
      sig { returns(UpdateLedger) }
      def update_ledger; end

      class UpdateLedger
        sig { returns(::String) }
        def __typename; end

        # `ledger`: Ledger!
        sig { returns(T.nilable(Ledger)) }
        def ledger; end

        class Ledger
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: SafeString!
          sig { returns(::String) }
          def ik; end

          # `name`: String!
          sig { returns(::String) }
          def name; end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end

  class UpdateLedgerEntry
    sig { returns(T.nilable(FragmentClient::Responses::UpdateLedgerEntry::Data)) }
    def data; end

    sig { returns(T.untyped) }
    def errors; end

    sig { returns(T::Hash[String, T.untyped]) }
    def original_hash; end

    class Data
      # `updateLedgerEntry`: UpdateLedgerEntryResponse!
      sig { returns(UpdateLedgerEntry) }
      def update_ledger_entry; end

      class UpdateLedgerEntry
        sig { returns(::String) }
        def __typename; end

        # `entry`: LedgerEntry!
        sig { returns(T.nilable(Entry)) }
        def entry; end

        class Entry
          # `id`: ID!
          sig { returns(::String) }
          def id; end

          # `ik`: String!
          sig { returns(::String) }
          def ik; end

          # `posted`: DateTime!
          sig { returns(::String) }
          def posted; end

          # `created`: DateTime!
          sig { returns(::String) }
          def created; end

          # `description`: String
          sig { returns(T.nilable(::String)) }
          def description; end

          # `lines`: LedgerLinesConnection!
          sig { returns(Lines) }
          def lines; end

          class Lines
            # `nodes`: [LedgerLine!]!
            sig { returns(T::Array[Nodes]) }
            def nodes; end

            class Nodes
              # `id`: ID!
              sig { returns(::String) }
              def id; end

              # `amount`: Int96!
              sig { returns(::String) }
              def amount; end

              # `account`: LedgerAccount!
              sig { returns(Account) }
              def account; end

              class Account
                # `path`: String!
                sig { returns(::String) }
                def path; end
              end
            end
          end

          # `groups`: [LedgerEntryGroup!]!
          sig { returns(T::Array[Groups]) }
          def groups; end

          class Groups
            # `key`: SafeString!
            sig { returns(::String) }
            def key; end

            # `value`: SafeString!
            sig { returns(::String) }
            def value; end
          end

          # `tags`: [LedgerEntryTag!]!
          sig { returns(T::Array[Tags]) }
          def tags; end

          class Tags
            # `key`: SafeString!
            sig { returns(::String) }
            def key; end

            # `value`: SafeString!
            sig { returns(::String) }
            def value; end
          end
        end

        # `code`: String!
        sig { returns(T.nilable(::String)) }
        def code; end

        # `message`: String!
        sig { returns(T.nilable(::String)) }
        def message; end

        # `retryable`: Boolean!
        sig { returns(T.nilable(T::Boolean)) }
        def retryable; end
      end
    end
  end
end

class FragmentClient::Entries::AuthCaptureV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, user_id: ::String, capture_amount: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, user_id:, capture_amount:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `user_id` (`String!`).
  sig { returns(::String) }
  def user_id; end

  # Schema parameter `capture_amount` (`Int96!`).
  sig { returns(::String) }
  def capture_amount; end

  # "auth_capture"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::Entry2faChallengeV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # "2fa_challenge"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::ReservedV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, type: ::String, class_: ::String, posted_: ::String, userId: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, type:, class_:, posted_:, userId:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `type` (`String!`).
  sig { returns(::String) }
  def type; end

  # Schema parameter `class` (`String!`). Exposed as `class_` because `class` is already taken; the wire name is unchanged.
  sig { returns(::String) }
  def class_; end

  # Schema parameter `posted` (`String!`). Exposed as `posted_` because `posted` is already taken; the wire name is unchanged.
  sig { returns(::String) }
  def posted_; end

  # Schema parameter `userId` (`String!`).
  sig { returns(::String) }
  def userId; end

  # "reserved"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::UserFundsAccountV1 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, amount: ::String, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, amount:, posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `amount` (`Int96!`).
  sig { returns(::String) }
  def amount; end

  # "user-funds-account"
  sig { returns(::String) }
  def self.entry_type; end

  # 1
  sig { returns(::Integer) }
  def self.type_version; end
end

class FragmentClient::Entries::UserFundsAccountV2 < ::FragmentClient::TypedLedgerEntry
  sig { params(ik: ::String, ledger_ik: ::String, amount: ::String, isExternal: T::Boolean, tagKeys: T::Array[::String], mode: T.untyped, feeAmount: T.nilable(::String), settledAt: T.nilable(::String), retryCount: T.nilable(::Integer), noteLines: T.nilable(T::Array[T.nilable(::String)]), channel: T.untyped, posted: T.nilable(::String), description: T.nilable(::String), tags: T.nilable(T::Array[T.untyped]), groups: T.nilable(T::Array[T.untyped]), conditions: T.nilable(T::Array[T.untyped])).void }
  def initialize(ik:, ledger_ik:, amount:, isExternal:, tagKeys:, mode:, feeAmount: T.unsafe(nil), settledAt: T.unsafe(nil), retryCount: T.unsafe(nil), noteLines: T.unsafe(nil), channel: T.unsafe(nil), posted: T.unsafe(nil), description: T.unsafe(nil), tags: T.unsafe(nil), groups: T.unsafe(nil), conditions: T.unsafe(nil)); end

  # Schema parameter `amount` (`Int96!`).
  sig { returns(::String) }
  def amount; end

  # Schema parameter `feeAmount` (`Int96`).
  sig { returns(T.nilable(::String)) }
  def feeAmount; end

  # Schema parameter `settledAt` (`DateTime`).
  sig { returns(T.nilable(::String)) }
  def settledAt; end

  # Schema parameter `isExternal` (`Boolean!`).
  sig { returns(T::Boolean) }
  def isExternal; end

  # Schema parameter `retryCount` (`Int`).
  sig { returns(T.nilable(::Integer)) }
  def retryCount; end

  # Schema parameter `tagKeys` (`[SafeString!]!`).
  sig { returns(T::Array[::String]) }
  def tagKeys; end

  # Schema parameter `noteLines` (`[String]`).
  sig { returns(T.nilable(T::Array[T.nilable(::String)])) }
  def noteLines; end

  # Schema parameter `mode` (`TransferMode!`).
  sig { returns(T.untyped) }
  def mode; end

  # Schema parameter `channel` (`TransferChannel`).
  sig { returns(T.untyped) }
  def channel; end

  # "user-funds-account"
  sig { returns(::String) }
  def self.entry_type; end

  # 2
  sig { returns(::Integer) }
  def self.type_version; end
end
