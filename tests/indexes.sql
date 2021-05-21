begin;

DO
$do$
    BEGIN
        CREATE EXTENSION IF NOT EXISTS pgtap;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '% %', SQLERRM, SQLSTATE;
    END;
$do$;

-- test indexes count
select plan(1);

select set_eq(
  'select count(*) from info.fk_indexes_check where existing_index is null',
  array [0],
  'Missing indexes linked to FK columns must be zero.');

select * from finish();

DO $$
DECLARE
  new_index_for_fk text;
BEGIN
  FOR new_index_for_fk IN select new_index from info.fk_indexes_check where existing_index is null LOOP
    RAISE NOTICE 'Index Creation Statement :: %', new_index_for_fk;
  END LOOP;
END;
$$;

rollback;
