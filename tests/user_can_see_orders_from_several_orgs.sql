begin;
SET client_min_messages=WARNING;
DO
$do$
    BEGIN
        CREATE EXTENSION IF NOT EXISTS pgtap;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '% %', SQLERRM, SQLSTATE;
    END;
$do$;

create or replace function mimic_user(email text, password text) returns void
    language plpgsql
as
$$
DECLARE
    oid int;
    sid int;
    uid int;
BEGIN
    SELECT organization_id, session_id, user_id into oid, sid, uid from authenticate(email, password);
    PERFORM set_config('jwt.claims.organization_id', oid::text, false);
    PERFORM set_config('jwt.claims.session_id', sid::text, false);
    PERFORM set_config('jwt.claims.user_id', uid::text, false);
    PERFORM set_config('jwt.claims.role', 'user_role', false);
    PERFORM set_config('role', 'user_role', false);
END;
$$;

truncate table private.session restart identity cascade;

truncate table private.user_account restart identity cascade;

truncate table orders restart identity cascade;

truncate table location restart identity cascade;

truncate table users restart identity cascade;

truncate table organizations restart identity cascade;

truncate table user_rights restart identity cascade;

-- Create test organizations
insert into organizations (id, name, domain, email)
values (1, 'root', 'testing.local', 'organization@testing.local');

insert into organizations (id, name, domain, email, parent_organization_id, receiver)
values (2, 'receiver', 'testing2.local', 'organization@testing2.local', 1, true);

insert into organizations (id, name, domain, email, parent_organization_id, sender)
values (3, 'sender', 'testing3.local', 'organization@testing3.local', 1, true);

insert into organizations (id, name, domain, email, parent_organization_id, port_agent)
values (4, 'agent', 'testing4.local', 'organization@testing4.local', 1, true);

insert into organizations (id, name, domain, email, parent_organization_id, ship_owner)
values (5, 'owner', 'testing5.local', 'organization@testing5.local', 1, true);

insert into organizations (id, name, domain, email, parent_organization_id)
values (6, 'not-referred-to', 'testing6.local', 'organization@testing6.local', 1);

insert into users (id, email, organization_id)
values (1, 'a@a.a', 1);

insert into users (id, email, organization_id)
values (2, 'b@b.b', 6);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (1, 'a@a.a', crypt('a', gen_salt('bf')), true, true, false);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (2, 'b@b.b', crypt('b', gen_salt('bf')), true, true, false);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders, create_and_edit_voyages,
                        create_and_edit_contracts)
values (1, 1, 1, true, true, true, true);

insert into user_rights(id, user_id, organization_id)
values (2, 2, 2);

insert into user_rights(id, user_id, organization_id)
values (3, 2, 3);

insert into user_rights(id, user_id, organization_id)
values (4, 2, 4);

insert into user_rights(id, user_id, organization_id)
values (5, 2, 5);

select mimic_user('a@a.a', 'a');

insert into location (id, organisation_id)
values (1, 1);

insert into location (id, organisation_id)
values (2, 1);

insert into ships (id)
values (1);

/* Test sender */
insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (1, 1, 1, 1);

insert into order_details (id, order_id, sender_organisation_id)
values (1, 1, 2);

insert into scheduled_order (id, planning_organisation_id, vessel_id, user_id, locked, shared, order_id,
                             loading_start, loading_duration, loading_end, discharging_start, discharging_duration,
                             discharging_end)
values (1, 1, 1, 1, false, true, 1, now(), 0, now(), now(), 0, now());


/* Test receiver */
insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (2, 1, 1, 1);

insert into order_details (id, order_id, receiver_organisation_id)
values (2, 2, 3);

insert into scheduled_order (id, planning_organisation_id, vessel_id, user_id, locked, shared, order_id,
                             loading_start, loading_duration, loading_end, discharging_start, discharging_duration,
                             discharging_end)
values (2, 1, 1, 1, false, true, 2, now(), 0, now(), now(), 0, now());


/* Test spot agent */
insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (3, 1, 1, 1);

insert into handled_by_spot (id, vessel_id, shared, order_id,
                             loading_start, loading_duration, loading_end, discharging_start, discharging_duration,
                             discharging_end)
values (1, 1, true, 3, now(), 0, now(), now(), 0, now());

insert into port_data (id, port_id, port_agent_org_id)
values (1, 1, 4);

insert into voyage_charter (id, organisation_id, shipowner_org_id) values (1, 1, 1);

insert into voyage_charter_port_data (id, voyage_charter_id, port_data_id) values (1, 1, 1);

insert into order_voyage_charter_relation (id, order_id, voyage_charter_id) values (1, 3, 1);

/* Test coa agent */
insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (4, 1, 1, 1);

insert into coa_contracts (id, user_id, end_date, shipowner_org_id, start_date)
values (1, 1, now(), 1, now());

insert into port_data (id, port_id, port_agent_org_id)
values (2, 1, 4);

insert into coa_contract_port_data (id, coa_contract_id, port_data_id)
values (1, 1, 2);

insert into handled_by_coa (id, coa_id, vessel_id, shared, order_id,
                            loading_start, loading_duration, loading_end, discharging_start, discharging_duration,
                            discharging_end)
values (1, 1, 1, true, 4, now(), 0, now(), now(), 0, now());

/* test ship owner, directly in order */
insert into orders (id, load_port_id, discharge_port_id, cargo_amount, charterer_organization_id, owner_organisation_id)
values (5, 1, 2, 1, 1, 5);

/* test ship owner, thru coa */
insert into coa_contracts (id, user_id, end_date, shipowner_org_id, start_date)
values (2, 1, now(), 5, now());

insert into orders (id, load_port_id, discharge_port_id, cargo_amount, charterer_organization_id)
values (6, 1, 2, 1, 1);

insert into handled_by_coa (id, coa_id, vessel_id, shared, order_id,
                            loading_start, loading_duration, loading_end, discharging_start, discharging_duration,
                            discharging_end)
values (2, 2, 1, true, 6, now(), 0, now(), now(), 0, now());

/* test ship owner, thru spot */
insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (7, 1, 1, 1);

insert into handled_by_spot (id, vessel_id, shared, order_id,
                             loading_start, loading_duration, loading_end, discharging_start, discharging_duration,
                             discharging_end, owner_organisation_id)
values (2, 1, true, 7, now(), 0, now(), now(), 0, now(), 5);

/* these don't work atm: load_port_agent_org_id, discharge_port_agent_id, should the columns be removed? */
insert into orders (id, load_port_id, discharge_port_id, cargo_amount, charterer_organization_id)
values (8, 1, 2, 1, 1);

insert into order_details (id, order_id, load_port_agent_org_id)
values (3, 8, 4);

insert into orders (id, load_port_id, discharge_port_id, cargo_amount, charterer_organization_id)
values (9, 2, 1, 1, 1);

insert into order_details (id, order_id, discharge_port_agent_id)
values (4, 9, 4);

select mimic_user('b@b.b', 'b');

select plan(1);

select set_eq(
               'select id from orders;',
               array [1, 2, 3, 4, 5, 6, 7 /*, 8, 9 */],
               'Should see orders from orgs with rights'
           );

select *
from finish();

rollback;
