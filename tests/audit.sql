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

truncate table private.email_verification restart identity cascade;

truncate table private.session restart identity cascade;

truncate table private.user_account restart identity cascade;

truncate table coa_contract_assortments restart identity cascade;

truncate table coa_contract_bunker restart identity cascade;

truncate table coa_contract_port_data restart identity cascade;

truncate table coa_contract_prices restart identity cascade;

truncate table coa_contract_ports restart identity cascade;

truncate table coa_contract_ships restart identity cascade;

truncate table demands restart identity cascade;

truncate table instructions restart identity cascade;

truncate table notification_receivers restart identity cascade;

truncate table port_regions restart identity cascade;

truncate table supply restart identity cascade;

truncate table quays restart identity cascade;

truncate table user_regions restart identity cascade;

truncate table regions restart identity cascade;

truncate table user_ships restart identity cascade;

truncate table vessel_secrets restart identity cascade;

truncate table tank_distance restart identity cascade;

truncate table location_working_hours restart identity cascade;

truncate table geographical_relation restart identity cascade;

truncate table route_override restart identity cascade;

truncate table channel_cost restart identity cascade;

truncate table channel restart identity cascade;

truncate table port_cost restart identity cascade;

truncate table holiday restart identity cascade;

truncate table geographical_entity restart identity cascade;

truncate table split_order restart identity cascade;

truncate table order_details restart identity cascade;

truncate table supply_contracts restart identity cascade;

truncate table cargo_exclusion restart identity cascade;

truncate table voyage_charter_to_contract restart identity cascade;

truncate table tc_contract restart identity cascade;

truncate table spot_negotiation restart identity cascade;

truncate table shipment_group_association restart identity cascade;

truncate table shipment_group restart identity cascade;

truncate table voyage_association restart identity cascade;

truncate table assortment_cleaning_requirements restart identity cascade;

truncate table off_hire restart identity cascade;

truncate table bunkering restart identity cascade;

truncate table parcel restart identity cascade;

truncate table vessel_hold restart identity cascade;

truncate table cargo_measurement restart identity cascade;

truncate table seen_message restart identity cascade;

truncate table chat restart identity cascade;

truncate table route_point_usage restart identity cascade;

truncate table routes restart identity cascade;

truncate table route_point restart identity cascade;

truncate table order_requirement_association restart identity cascade;

truncate table vessel_fulfills_requirement_association restart identity cascade;

truncate table location_requirement_association restart identity cascade;

truncate table special_requirements restart identity cascade;

truncate table handled_by_spot restart identity cascade;

truncate table voyage_charter_port_call_relation restart identity cascade;

truncate table order_port_call_relation restart identity cascade;

truncate table single_event_port_call_relation restart identity cascade;

truncate table port_notice restart identity cascade;

truncate table laytime_responsibility restart identity cascade;

truncate table port_activity restart identity cascade;

truncate table statement_of_facts restart identity cascade;

truncate table bill_of_lading_data restart identity cascade;

truncate table bill_of_lading restart identity cascade;

truncate table cost_split_on_single_event restart identity cascade;

truncate table single_event restart identity cascade;

truncate table cost_split_on_scheduled_order restart identity cascade;

truncate table scheduled_order restart identity cascade;

truncate table actual_cost restart identity cascade;

truncate table receiver_organizations restart identity cascade;

truncate table sender_organizations restart identity cascade;

truncate table handled_by_coa restart identity cascade;

truncate table coa_contracts restart identity cascade;

truncate table port_call_files restart identity cascade;

truncate table files restart identity cascade;

truncate table voyage restart identity cascade;

truncate table port_call restart identity cascade;

truncate table voyage_charter_order_freight restart identity cascade;

truncate table order_voyage_charter_relation restart identity cascade;

truncate table voyage_charter_port_data restart identity cascade;

truncate table voyage_charter restart identity cascade;

truncate table ships restart identity cascade;

truncate table vessel_info restart identity cascade;

truncate table class_society_association restart identity cascade;

truncate table ice_class restart identity cascade;

truncate table classification_society restart identity cascade;

truncate table port_data restart identity cascade;

truncate table user_settings restart identity cascade;

truncate table order_attribute_associations restart identity cascade;

truncate table orders restart identity cascade;

truncate table assortments restart identity cascade;

truncate table assortment_groups restart identity cascade;

truncate table cargo_units restart identity cascade;

truncate table location restart identity cascade;

truncate table countries restart identity cascade;

truncate table shipment restart identity cascade;

truncate table users restart identity cascade;

truncate table order_attributes restart identity cascade;

truncate table organizations restart identity cascade;

truncate table user_rights restart identity cascade;

-- Create test organizations
insert into organizations (id, name, domain, email)
values (1, 'Testing', 'testing.local', 'organization@testing.local');

insert into organizations (id, name, domain, email)
values (2, 'Testing2', 'testing2.local', 'organization@testing2.local');

insert into organizations (id, name, domain, email, parent_organization_id)
values (3, 'Testing3', 'testing3.local', 'organization@testing3.local', 1);

insert into users (id, email, organization_id)
values (1, 'a@a.a', 1);

insert into users (id, email, organization_id)
values (2, 'b@b.b', 2);

insert into users (id, email, organization_id)
values (3, 'not-admin@b.b', 2);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (1, 'a@a.a', crypt('a', gen_salt('bf')), true, true, false);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (1, 1, 1, true, true);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (2, 2, 2, true, true);

insert into user_rights(id, user_id, organization_id, org_admin, create_and_edit_orders)
values (3, 3, 2, false, false);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (2, 'b@b.b', crypt('b', gen_salt('bf')), true, true, false);

insert into private.user_account (user_id, email, password_hash, activated, verified, system_admin)
values (3, 'not-admin@b.b', crypt('c', gen_salt('bf')), true, true, false);

select mimic_user('a@a.a', 'a');

insert into location (id, organisation_id)
values (1, 1);

insert into assortment_groups (id, name, charterer_org_id)
values (1, 'a', 1);

insert into assortments (id, name, organization_id, charterer_org_id)
values (1, 'a', 1, 1);

insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (1, 1, 1, 1);

insert into ships (id, user_id, organization_id)
values (1, 1, 1);

insert into port_call (id, vessel_id, location_id, first_start, last_end, root_org)
values (1, 1, 1, now(), now(), 1);

insert into order_port_call_relation (id, port_call_id, order_id, is_load_port)
values (1, 1, 1, false);

insert into port_notice (id, port_call_id, user_id)
values (1, 1, 1);

insert into files (id, uri, type, vessel_id, user_id)
values (1, 'a', 'sof', 1, 1);

insert into files (id, uri, type, vessel_id, user_id)
values (2, 'aa', 'sof', 1, 1);

insert into port_call_files (id, file_id, port_call_id)
values (1, 1, 1);

insert into statement_of_facts (id, port_call_id, user_id)
values (1, 1, 1);

insert into special_requirements (id, name, organization_id)
values (1, 'a', 1);

insert into location_requirement_association (id, special_requirement_id, location_id)
values (1, 1, 1);

select mimic_user('b@b.b', 'b');

insert into location (id, organisation_id)
values (2, 2);

insert into location (id, organisation_id)
values (3, 2);

insert into location (id, organisation_id)
values (4, 2);

insert into assortment_groups (id, name, charterer_org_id)
values (2, 'b', 2);

insert into assortment_groups (id, name, charterer_org_id)
values (3, 'c', 2);

insert into assortment_groups (id, name, charterer_org_id)
values (4, 'd', 2);

insert into assortments (id, name, organization_id, charterer_org_id)
values (2, 'b', 2, 2);

insert into assortments (id, name, organization_id, charterer_org_id)
values (3, 'c', 2, 2);

insert into assortment_cleaning_requirements (id, next_assortment_group, previous_assortment_group, voyages, distance,
                                              tanks)
values (1, 2, 3, 1, 1, 1);

insert into orders (id, discharge_port_id, cargo_amount, charterer_organization_id)
values (2, 2, 2, 2);

insert into ships (id, user_id, organization_id)
values (2, 2, 2);

insert into special_requirements (id, name, organization_id)
values (2, 'b', 2);

insert into special_requirements (id, name, organization_id)
values (3, 'c', 2);

insert into special_requirements (id, name, organization_id)
values (4, 'd', 2);

insert into location_requirement_association (id, special_requirement_id, location_id)
values (2, 2, 2);

select plan(37);

select has_table(
               'public',
               'organizations',
               'Check that organizations table is present'
           );

select table_privs_are(
               'public',
               'organizations',
               'user_role',
               array ['SELECT', 'INSERT', 'UPDATE', 'DELETE']
           );

select mimic_user('a@a.a', 'a');

select set_eq(
               'select name from organizations;',
               array ['Testing', 'Testing3'],
               'Organisation should only see their own organisation and suborganisations'
           );

select mimic_user('b@b.b', 'b');

select set_eq(
               'select name from organizations;',
               array ['Testing2'],
               'Organisation should only see their own organisation and suborganisations'
           );

prepare insert_assortment_into_other_root_org as
    insert into assortments (id, name, organization_id)
    values (4, 'a', 1);

select throws_ok('insert_assortment_into_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.1. admin of secondroot can create assortments for firstroot');

/*
prepare insert_organization_right_for_other_root_org as
    insert into organization_rights (grantor_organization_id, grantee_organization_id, port_id)
    values (2, 1, 1);

select lives_ok('insert_organization_right_for_other_root_org',
                'should be possible to grant cross org rights: 6.1.2. Admin of secondroot can create OrganizationRight where granteeOrganization is from firstroot');
*/

prepare insert_assortment_cleaning_requirements_into_other_root_org as
    insert into assortment_cleaning_requirements (next_assortment_group)
    values (1);

select throws_ok('insert_assortment_cleaning_requirements_into_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.3. Admin of secondroot can create AssortmentCleaningRequirement where nextAssortmentGroup is from firstroot');

prepare insert_assortment_with_group_from_other_root_org as
    insert into assortments (id, name, organization_id, assortment_group)
    values (5, 'a', 2, 1);

select throws_ok('insert_assortment_with_group_from_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.4. Admin of secondroot can create Assortment where assortmentGroup is from firstroot
');

prepare insert_location_with_parent_from_other_root_org as
    insert into location (id, name, organisation_id, parent_location_id)
    values (5, 'b', 2, 1);

select throws_ok('insert_location_with_parent_from_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.5. Admin of secondroot can create Port where parentLocationId is from firstroot
');

prepare insert_supply_contract_with_sender_from_other_root_org as
    insert into supply_contracts (sender_organization_id)
    values (1);

select throws_ok('insert_supply_contract_with_sender_from_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.6. Admin of secondroot can create Supply contract where senderOrganizationId is from firstroot
');

select mimic_user('a@a.a', 'a');

prepare insert_order_with_sender_and_receiver_from_other_root_org as
    insert into order_details (order_id, sender_organisation_id, receiver_organisation_id)
    values (1, 2, 2);

select throws_ok('insert_order_with_sender_and_receiver_from_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.7. User of firstroot can create Order where receiverOrganizationId and senderOrganisationId are from secondroot
');

select mimic_user('b@b.b', 'b');

prepare update_port_call_from_other_root_org as
    update port_notice
    set ata_berth = now()
    where id = 1
    returning id;

select is_empty('update_port_call_from_other_root_org',
                'should not affect any rows: 6.1.8. Port call Notice of readiness can be edited by admin of another root company
');

prepare select_port_call_from_other_root_org as
    select port_call_id
    from port_call_files
    where id = 1;

select is_empty('select_port_call_from_other_root_org',
                'should not give any results: 6.1.9. Port call PortCallsDocuments can be viewed by admin of another root company
');

prepare update_port_call_statement_of_facts_from_other_root_org as
    update statement_of_facts
    set user_id = 2
    where id = 1
    returning id;

select is_empty('update_port_call_statement_of_facts_from_other_root_org',
                'should get insufficient_privilege: 6.1.10. Port call Statement of Facts can be edited by admin of another root company
');

prepare create_port_call_with_data_from_other_root_org as
    insert into port_call (id, vessel_id, location_id, first_start, last_end, root_org)
    values (2, 1, 1, now(), now(), 2);

select throws_ok('create_port_call_with_data_from_other_root_org', 42501, null,
                 'should get insufficient_privilege: 6.1.11. Secondroot admin can create port calls with vessels and locations of firstroot
');

select mimic_user('not-admin@b.b', 'c');

prepare edit_restricted_profile_params_as_non_admin_1 as
    update users
    set show_admin = true
    where id = 3
    returning id;

prepare edit_restricted_profile_params_as_non_admin_2 as
    update users
    set user_type = 'ship'
    where id = 3
    returning id;

prepare edit_restricted_profile_params_as_non_admin_3 as
    update users
    set user_id = 2
    where id = 3
    returning id;

select is_empty('edit_restricted_profile_params_as_non_admin_1',
                'should not affect any row: 6.1.12. Non-admin can edit restricted profile parameters for own account
');

select is_empty('edit_restricted_profile_params_as_non_admin_2',
                'should not affect any row: 6.1.12. Non-admin can edit restricted profile parameters for own account
');

select is_empty('edit_restricted_profile_params_as_non_admin_3',
                'should not affect any row: 6.1.12. Non-admin can edit restricted profile parameters for own account
');

prepare insert_assortment_group_as_non_admin as
    insert into assortment_groups (id, name, user_id, charterer_org_id)
    values (5, 'e', 3, 2);

select throws_ok('insert_assortment_group_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.13. Non-admin user can create and edit Assortment Groups
');

prepare update_assortment_group_as_non_admin as
    update assortment_groups
    set name = 'f'
    where id = 2
    returning id;

select is_empty('update_assortment_group_as_non_admin',
                'should not affect any row: 6.1.13. Non-admin user can create and edit Assortment Groups
');

prepare insert_assortment_as_non_admin as
    insert into assortments (id, name, user_id, charterer_org_id, organization_id)
    values (6, 'd', 3, 2, 2);

select throws_ok('insert_assortment_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.14. Non-admin user can create, edit and delete Assortments
');

prepare update_assortment_as_non_admin as
    update assortments
    set name = 'd'
    where id = 2
    returning id;

select is_empty('update_assortment_as_non_admin',
                'should not affect any row: 6.1.14. Non-admin user can create, edit and delete Assortments
');

prepare delete_assortment_as_non_admin as
    delete
    from assortments
    where id = 2
    returning id;

select is_empty('delete_assortment_as_non_admin',
                'should not affect any row: 6.1.14. Non-admin user can create, edit and delete Assortments
');

prepare insert_assortment_cleaning_requirements_as_non_admin as
    insert into assortment_cleaning_requirements (next_assortment_group, previous_assortment_group, voyages, distance,
                                                  tanks)
    values (3, 4, 1, 1, 1);

select throws_ok('insert_assortment_cleaning_requirements_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.15. Non-admin user can create, edit and delete Assortment Cleaning Requirements
');

prepare update_assortment_cleaning_requirements_as_non_admin as
    update assortment_cleaning_requirements
    set voyages = 2
    where id = 2
    returning id;

select is_empty('update_assortment_cleaning_requirements_as_non_admin',
                'should not affect any row: 6.1.15. Non-admin user can create, edit and delete Assortment Cleaning Requirements
');

prepare delete_assortment_cleaning_requirements_as_non_admin as
    delete
    from assortments
    where id = 2
    returning id;

select is_empty('delete_assortment_cleaning_requirements_as_non_admin',
                'should not affect any row: 6.1.15. Non-admin user can create, edit and delete Assortment Cleaning Requirements
');


prepare insert_port_as_non_admin as
    insert into location (id, name, latitude, longitude)
    values (6, 'non-admin', 0, 0);

select throws_ok('insert_port_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.16. Non-admin user can create and delete Ports
');

prepare update_port_as_non_admin as
    update location
    set air_draft = 2
    where id = 2
    returning id;

select is_empty('update_port_as_non_admin',
                'should not affect any row: 6.1.16. Non-admin user can create and delete Ports
');

prepare delete_port_as_non_admin as
    delete
    from location
    where id = 4
    returning id;

select is_empty('delete_port_as_non_admin',
                'should not affect any row: 6.1.16. Non-admin user can create and delete Ports
');


prepare insert_ship_as_non_admin as
    insert into ships (id, name)
    values (3, 'non-admin');

select throws_ok('insert_ship_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.17. Non-admin user can create, edit and delete Ships
');

prepare update_ship_as_non_admin as
    update ships
    set air_draft = 2
    where id = 2
    returning id;

select is_empty('update_ship_as_non_admin',
                'should not affect any row: 6.1.17. Non-admin user can create, edit and delete Ships
');

prepare delete_ship_as_non_admin as
    delete
    from ships
    where id = 2
    returning id;

select is_empty('delete_ship_as_non_admin',
                'should not affect any row: 6.1.17. Non-admin user can create, edit and delete Ships
');


prepare insert_special_requirements_as_non_admin as
    insert into special_requirements (id, name, organization_id)
    values (5, 'non-admin', 2);

select throws_ok('insert_special_requirements_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.18. Non-admin user can create, edit and delete Special Requirements
');

prepare update_special_requirements_as_non_admin as
    update special_requirements
    set name = 'd'
    where id = 2
    returning id;

select is_empty('update_special_requirements_as_non_admin',
                'should not affect any row: 6.1.18. Non-admin user can create, edit and delete Special Requirements
');

prepare delete_special_requirements_as_non_admin as
    delete
    from special_requirements
    where id = 3
    returning id;

select is_empty('delete_special_requirements_as_non_admin',
                'should not affect any row: 6.1.18. Non-admin user can create, edit and delete Special Requirements
');


prepare insert_location_special_requirements_as_non_admin as
    insert into location_requirement_association (id, special_requirement_id, location_id)
    values (3, 2, 3);

select throws_ok('insert_location_special_requirements_as_non_admin', 42501, null,
                 'should get insufficient_privilege: 6.1.19. Non-admin user can create Port Special Requirements
');

prepare update_location_special_requirements_as_non_admin as
    update location_requirement_association
    set location_id = 4
    where id = 2
    returning id;

select is_empty('update_location_special_requirements_as_non_admin',
                'should not affect any row: 6.1.19. Non-admin user can edit Port Special Requirements
');

prepare delete_location_special_requirements_as_non_admin as
    delete
    from special_requirements
    where id = 4
    returning id;

select is_empty('delete_location_special_requirements_as_non_admin',
                'should not affect any row: 6.1.19. Non-admin user can delete Port Special Requirements
');

select *
from finish();

rollback;
