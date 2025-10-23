use starknet::contract::ContractAddress;
use starknet::context::{get_block_timestamp, get_caller_address};
use starknet::storage::LegacyMap;
use starknet::crypto::pedersen_hash::pedersen_hash;
use starknet::macros::panic_with_felt252;
use array::ArrayTrait;
use array::Array;

const ERR_NOT_ADMIN: felt252 = 1;
const ERR_ROW_TOO_LOW: felt252 = 2;
const ERR_ROW_TOO_HIGH: felt252 = 3;
const ERR_ROW_EXISTS: felt252 = 4;
const ERR_ROW_ORDER: felt252 = 5;
const ERR_ROW_UNKNOWN: felt252 = 6;
const ERR_PLOT_EXISTS: felt252 = 7;
const ERR_PLOT_UNKNOWN: felt252 = 8;
const ERR_INVALID_HASH: felt252 = 9;

#[starknet::contract]
mod campo_santo {
    use super::ContractAddress;
    use super::LegacyMap;
    use super::get_block_timestamp;
    use super::get_caller_address;
    use super::pedersen_hash;
    use super::panic_with_felt252;
    use super::ArrayTrait;
    use super::Array;
    use super::ERR_NOT_ADMIN;
    use super::ERR_ROW_TOO_LOW;
    use super::ERR_ROW_TOO_HIGH;
    use super::ERR_ROW_EXISTS;
    use super::ERR_ROW_ORDER;
    use super::ERR_ROW_UNKNOWN;
    use super::ERR_PLOT_EXISTS;
    use super::ERR_PLOT_UNKNOWN;
    use super::ERR_INVALID_HASH;

    #[storage]
    struct Storage {
        admin: ContractAddress,
        last_row: u8,
        row_count: u32,
        row_by_index: LegacyMap<u32, u8>,
        row_exists: LegacyMap<u8, u8>,
        plot_counts: LegacyMap<u8, u32>,
        plot_exists: LegacyMap<(u8, u32), u8>,
        occupant_commitment: LegacyMap<(u8, u32), felt252>,
        metadata_commitment: LegacyMap<(u8, u32), felt252>,
        plot_created_at: LegacyMap<(u8, u32), u64>,
        plot_updated_at: LegacyMap<(u8, u32), u64>,
        perpetual_plot: LegacyMap<(u8, u32), u8>,
    }

    #[event]
    fn RowRegistered(row: u8) {}

    #[event]
    fn PlotRegistered(
        row: u8,
        plot: u32,
        occupant_commitment: felt252,
        metadata_commitment: felt252,
        timestamp: u64,
    ) {
    }

    #[event]
    fn PlotUpdated(
        row: u8,
        plot: u32,
        occupant_commitment: felt252,
        metadata_commitment: felt252,
        timestamp: u64,
    ) {
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
        self.last_row.write(0_u8);
        self.row_count.write(0_u32);
    }

    #[external(v0)]
    fn set_admin(ref self: ContractState, new_admin: ContractAddress) {
        assert_admin(ref self);
        self.admin.write(new_admin);
    }

    #[external(v0)]
    fn register_row(ref self: ContractState, row: u8) {
        assert_admin(ref self);
        ensure_valid_row(row);

        let exists = self.row_exists.read(row);
        if exists != 0_u8 {
            panic_with_felt252(ERR_ROW_EXISTS);
        }

        let last_row = self.last_row.read();
        if row <= last_row {
            panic_with_felt252(ERR_ROW_ORDER);
        }

        let index = self.row_count.read();
        self.row_exists.write(row, 1_u8);
        self.row_by_index.write(index, row);
        self.row_count.write(index + 1_u32);
        self.last_row.write(row);

        self.emit(RowRegistered { row: row });
    }

    #[external(v0)]
    fn register_plot(
        ref self: ContractState,
        row: u8,
        plot: u32,
        occupant_commitment: felt252,
        metadata_commitment: felt252,
    ) {
        assert_admin(ref self);
        ensure_row_exists(ref self, row);
        ensure_hash_is_valid(occupant_commitment);

        let key = (row, plot);
        let exists = self.plot_exists.read(key);
        if exists != 0_u8 {
            panic_with_felt252(ERR_PLOT_EXISTS);
        }

        let timestamp = get_block_timestamp();
        self.plot_exists.write(key, 1_u8);
        self.occupant_commitment.write(key, occupant_commitment);
        self.metadata_commitment.write(key, metadata_commitment);
        self.perpetual_plot.write(key, 1_u8);
        self.plot_created_at.write(key, timestamp);
        self.plot_updated_at.write(key, timestamp);

        let count = self.plot_counts.read(row);
        self.plot_counts.write(row, count + 1_u32);

        self.emit(PlotRegistered {
            row: row,
            plot: plot,
            occupant_commitment: occupant_commitment,
            metadata_commitment: metadata_commitment,
            timestamp: timestamp,
        });
    }

    #[external(v0)]
    fn update_plot_commitments(
        ref self: ContractState,
        row: u8,
        plot: u32,
        occupant_commitment: felt252,
        metadata_commitment: felt252,
    ) {
        assert_admin(ref self);
        ensure_row_exists(ref self, row);
        ensure_hash_is_valid(occupant_commitment);

        let key = (row, plot);
        let exists = self.plot_exists.read(key);
        if exists == 0_u8 {
            panic_with_felt252(ERR_PLOT_UNKNOWN);
        }

        let timestamp = get_block_timestamp();
        self.occupant_commitment.write(key, occupant_commitment);
        self.metadata_commitment.write(key, metadata_commitment);
        self.plot_updated_at.write(key, timestamp);

        self.emit(PlotUpdated {
            row: row,
            plot: plot,
            occupant_commitment: occupant_commitment,
            metadata_commitment: metadata_commitment,
            timestamp: timestamp,
        });
    }

    #[view]
    fn get_admin(self: @ContractState) -> ContractAddress {
        self.admin.read()
    }

    #[view]
    fn get_row_count(self: @ContractState) -> u32 {
        self.row_count.read()
    }

    #[view]
    fn get_row_by_index(self: @ContractState, index: u32) -> u8 {
        self.row_by_index.read(index)
    }

    #[view]
    fn get_row_details(self: @ContractState, row: u8) -> (bool, u32) {
        let exists = self.row_exists.read(row);
        let count = self.plot_counts.read(row);
        (exists != 0_u8, count)
    }

    #[view]
    fn get_plot_details(
        self: @ContractState,
        row: u8,
        plot: u32,
    ) -> (felt252, felt252, bool, u64, u64) {
        let key = (row, plot);
        let exists = self.plot_exists.read(key);
        if exists == 0_u8 {
            panic_with_felt252(ERR_PLOT_UNKNOWN);
        }

        let occupant_hash = self.occupant_commitment.read(key);
        let metadata_hash = self.metadata_commitment.read(key);
        let created_at = self.plot_created_at.read(key);
        let updated_at = self.plot_updated_at.read(key);
        let perpetual = self.perpetual_plot.read(key);

        (occupant_hash, metadata_hash, perpetual != 0_u8, created_at, updated_at)
    }

    #[view]
    fn list_rows(self: @ContractState) -> Array<u8> {
        let mut rows: Array<u8> = ArrayTrait::new();
        let total = self.row_count.read();
        let mut index = 0_u32;
        loop {
            if index == total {
                break;
            }

            let row = self.row_by_index.read(index);
            rows.append(row);
            index = index + 1_u32;
        }
        rows
    }

    #[view]
    fn compute_commitment(
        self: @ContractState,
        hashed_payload: felt252,
        secret: felt252,
    ) -> felt252 {
        pedersen_hash(hashed_payload, secret)
    }

    #[view]
    fn verify_plot_commitment(
        self: @ContractState,
        row: u8,
        plot: u32,
        hashed_payload: felt252,
        secret: felt252,
    ) -> bool {
        let key = (row, plot);
        let exists = self.plot_exists.read(key);
        if exists == 0_u8 {
            return false;
        }

        let expected = pedersen_hash(hashed_payload, secret);
        let stored = self.occupant_commitment.read(key);
        expected == stored
    }

    fn assert_admin(ref self: ContractState) {
        let caller = get_caller_address();
        let admin = self.admin.read();
        if caller != admin {
            panic_with_felt252(ERR_NOT_ADMIN);
        }
    }

    fn ensure_row_exists(ref self: ContractState, row: u8) {
        ensure_valid_row(row);
        let exists = self.row_exists.read(row);
        if exists == 0_u8 {
            panic_with_felt252(ERR_ROW_UNKNOWN);
        }
    }

    fn ensure_valid_row(row: u8) {
        if row < 65_u8 {
            panic_with_felt252(ERR_ROW_TOO_LOW);
        }
        if row > 90_u8 {
            panic_with_felt252(ERR_ROW_TOO_HIGH);
        }
    }

    fn ensure_hash_is_valid(hash: felt252) {
        if hash == 0 {
            panic_with_felt252(ERR_INVALID_HASH);
        }
    }
}
