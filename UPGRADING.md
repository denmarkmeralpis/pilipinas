# Upgrading to 1.2.0

1.2.0 refreshes the bundled data to the PSA PSGC of 30 September 2026, and `rake pilipinas:load` now deletes
database rows that are no longer in that data. How much work the upgrade takes depends on where you start:

| You are on | What to do |
|---|---|
| 0.0.1 | [From 0.0.1](#from-001), then [Data changes](#data-changes-everyone) |
| Any 1.x, YAML-backed API only (`Pilipinas::Region`, …) | [Data changes](#data-changes-everyone) |
| 1.1.2 – 1.1.6, with the `pilipinas_*` tables | [Data changes](#data-changes-everyone), then [Database seeded by 1.1.2 – 1.1.6](#database-seeded-by-112--116) |
| 1.0.0 – 1.1.1, with the `pilipinas_*` tables | [Data changes](#data-changes-everyone), then [Database seeded by 1.0.0 – 1.1.1](#database-seeded-by-100--111) |

Not sure which version seeded your tables? Run this in `bin/rails console`. `true` means the rows came from 1.0.0 – 1.1.1:

```ruby
Pilipinas::Db::Region.where(location_id: nil).exists?
```

---

## From 0.0.1

1.0.0 rewrote the gem. Before following the rest of this guide:

- **Ruby 3.4 or newer is required.**
- **Results are frozen.** `.all` returns a frozen Array and every record is frozen, so code that modified them now raises `FrozenError`.
- **The lookups you used still work.** `.all`, `.find_by_code`, `.find_by_name` and `region.provinces`-style traversal are unchanged, and so are the codes.
- **The ActiveRecord tables are new and optional.** To use them, follow [Rails / ActiveRecord integration](README.md#rails--activerecord-integration-optional) in the README as a fresh install.

---

## Data changes (everyone)

**Codes are stable.** The YAML-backed `code` (`Pilipinas::Barangay.find_by_code("…")`) of every location that still exists is the same from 0.0.1 through 1.2.0. In the database tables, the same number is stored in `location_id`.

**Some locations were removed.** 1.2.0 drops 1 province, 5 cities/municipalities and 181 barangays, and adds 1 region, 4 provinces, 13 cities/municipalities and 164 barangays. The province and the cities/municipalities were split or re-coded by the PSA:

| Removed | Code | Replaced by | Code |
|---|---|---|---|
| MAGUINDANAO (province) | 42589 | Maguindanao del Norte, Maguindanao del Sur | 43781, 43782 |
| DON MARCELINO | 38031 | Don Marcelino | 43783 |
| JOSE ABAD SANTOS (TRINIDAD) | 38069 | Jose Abad Santos | 43784 |
| MALITA | 38166 | Malita | 43785 |
| SANTA MARIA | 38268 | Santa Maria | 43786 |
| SARANGANI | 38291 | Sarangani | 43787 |

To check the codes your application stores, look each one up. Removed codes return `nil`:

```ruby
missing = stored_barangay_codes.reject { |code| Pilipinas::Barangay.find_by_code(code) }
```

**Names follow PSA spelling.** Name lookups ignore case, so names whose only change was case still match. Names whose wording changed don't: 4 regions, 3 provinces, 222 cities/municipalities and 4,991 barangays (e.g. `NAGA CITY` → `City of Naga`). Look locations up by code where you can, and re-check any names you store or hard-code.

---

## Database seeded by 1.1.2 – 1.1.6

Your rows already have a `location_id`, so the load updates them in place and they keep their `id`s. Only the rows for removed locations are deleted.

1. **Upgrade the gem** (`bundle update pilipinas`).

2. **Preview the deletions.** This runs the real load inside a transaction, prints the rows it deleted, then rolls everything back. It does all the work of a real load and holds a transaction open the whole time, so run it against a copy of your production data:

   ```ruby
   # bin/rails runner preview_pilipinas_upgrade.rb
   tables = [Pilipinas::Db::Region, Pilipinas::Db::Province, Pilipinas::Db::City, Pilipinas::Db::Barangay]
   before = tables.to_h { |t| [t, t.pluck(:id, :location_id, :name).to_h { |id, *rest| [id, rest] }] }

   ActiveRecord::Base.transaction do
     Pilipinas::Loader.run
     tables.each do |t|
       deleted = before[t].keys - t.pluck(:id)
       puts "#{t.table_name}: #{deleted.size} row(s) would be deleted"
       deleted.each { |id| puts "  id=#{id} location_id=#{before[t][id][0]} #{before[t][id][1]}" }
     end
     raise ActiveRecord::Rollback
   end
   ```

   Expect 1 province, 5 cities/municipalities and 181 barangays. If it raises `Pilipinas::Error` about a foreign key instead, some of your rows reference a location that is being removed. Step 3 fixes that.

3. **Re-point references to removed rows.** Use the [replacement table](#data-changes-everyone) for the province and cities/municipalities. Decide case by case for barangays.

4. **Run the load:**

   ```sh
   rake pilipinas:load
   ```

   It prints how many rows it removed from each table.

5. **Without a database foreign key, find references that now point at nothing.** For example:

   ```ruby
   Address.where.not(barangay_id: nil).where.not(barangay_id: Pilipinas::Db::Barangay.select(:id))
   ```

---

## Database seeded by 1.0.0 – 1.1.1

These versions stored only `code` and `name`. `location_id` was left NULL, and `code` held the YAML-backed code rather than the PSA code. Running the 1.2.0 load as-is would delete every one of those rows and insert new ones with new `id`s:
- **With a database foreign key,** the load stops with `Pilipinas::Error`.
- **Without one,** every reference silently breaks.

To avoid that, copy the old code into `location_id` first. The YAML-backed code *is* the location's `location_id`, so the load then recognises each row and updates it in place.

1. **Upgrade the gem** (`bundle update pilipinas`).

2. **Backfill `location_id` (once):**

   ```ruby
   # bin/rails runner backfill_pilipinas_location_ids.rb
   ActiveRecord::Base.transaction do
     [Pilipinas::Db::Region, Pilipinas::Db::Province, Pilipinas::Db::City, Pilipinas::Db::Barangay].each do |table|
       table.where(location_id: nil).pluck(:id, :code).each do |id, code|
         table.where(id: id).update_all(location_id: code.to_i)
       end
     end
   end
   ```

   After the load, these rows keep their `id`s, and `code` changes to the PSA code (e.g. `5` → `133901001`). If your application stored the old code, look rows up by `location_id` from now on.

3. **Continue with steps 2 – 5 of [Database seeded by 1.1.2 – 1.1.6](#database-seeded-by-112--116).** The preview will show a few more deletions than listed there. The old YAML files grouped Metro Manila by district, and those groups have no row in the full data:

   | Old row | Becomes |
   |---|---|
   | Provinces `NCR, SECOND DISTRICT`, `NCR, THIRD DISTRICT`, `NCR, FOURTH DISTRICT` | Deleted. Their cities now sit under province `METRO MANILA` (`location_id` 2). |
   | Province `NCR, CITY OF MANILA, FIRST DISTRICT` (`location_id` 2) | Kept, renamed `METRO MANILA`. |
   | City `CITY OF MANILA` | Deleted. Manila is listed by district instead (e.g. `Tondo I/II`). |

---

## If `rake pilipinas:load` stops with an error

- **`Pilipinas::Error: pilipinas:load requires a unique index on the location_id column`**: your tables are missing the `location_id` unique indexes. Add them, then re-run the load:

  ```sh
  rails generate pilipinas:code_indexes
  rails db:migrate
  ```

- **`Pilipinas::Error: pilipinas:load could not delete rows from … foreign key`**: rows in your application still reference a location that is being removed. Nothing was changed. Re-point those references (step 3 above), then re-run the load.
