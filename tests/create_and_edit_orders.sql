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
values (1, 'Testing', 'testing.local', 'organization@testing.local');

insert into organizations (id, name, domain, email, parent_organization_id)
values (2, 'Testing2', 'testing2.local', 'organization@testing2.local', 1);

insert into organizations (id, name, domain, email, parent_organization_id)
values (3, 'Testing3', 'testing3.local', 'organization@testing3.local', 2);

insert into organizations (id, name, domain, email, parent_organization_id)
values (4, 'Testing4', 'testing4.local', 'organization@testing4.local', 1);

insert into users (id, email, organization_id)
values (1, 'a@a.a', 1);

insert into users (id, email, organization_id)
values (2, 'b@b.b', 2);

insert into users (id, email, organization_id)
values (3, 'c@c.c', 3);

insert into users (id, email, organization_id)
values (4, 'd@d.d', 4);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (1, 'a@a.a', crypt('a', gen_salt('bf')), true, true, false);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (2, 'b@b.b', crypt('b', gen_salt('bf')), true, true, false);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (3, 'c@c.c', crypt('c', gen_salt('bf')), true, true, false);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (4, 'd@d.d', crypt('d', gen_salt('bf')), true, true, false);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (1, 1, 1, true, true);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (2, 2, 2, false, true);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (3, 3, 3, false, true);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (4, 4, 2, false, true);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (5, 4, 4, false, true);

select mimic_user('a@a.a', 'a');

insert into location (id, organisation_id)
values (1, 1);

insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (1, 1, 1, 1);

select mimic_user('b@b.b', 'b');

insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (2, 1, 1, 2);

select mimic_user('c@c.c', 'c');

insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (3, 1, 1, 3);

select plan(7);

select mimic_user('d@d.d', 'd');

select set_eq(
               'select unnest(descendants) from organizations where id = 2;',
               array [2, 3],
               'descendants should include sub-orgs'
           );

select set_eq(
               'select id from orders;',
               array [2, 3],
               'Should see orders from orgs (and sub-orgs) with rights'
           );

prepare insert_order_across_org as
    insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
    values (4, 1, 1, 3);

select lives_ok('insert_order_across_org', 'should be able to add orders in orgs with rights');

insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (5, 1, 1, 4);

select set_eq(
               'select id from orders;',
               array [2, 3, 4, 5],
               'Should see orders from orgs (and sub-orgs) with rights'
           );

select mimic_user('b@b.b', 'b');

select set_eq(
               'select id from orders;',
               array [2, 3, 4],
               'Should see orders from orgs (and sub-orgs) with rights'
           );

prepare insert_order_into_root_org_without_rights as
    insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
    values (6, 1, 1, 4);

select throws_ok('insert_order_into_root_org_without_rights', 42501, null,
                 'should get insufficient_privilege');


select mimic_user('a@a.a', 'a');

select set_eq(
               'select id from orders;',
               array [1, 2, 3, 4, 5],
               'Org admin should see all orders'
           );

select *
from finish();

rollback;
