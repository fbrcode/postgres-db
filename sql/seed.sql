begin;
drop schema if exists seed cascade;
create schema seed;


create type seed.user_account as (
  user_id integer,
  email text,
  password text,
  user_type public.user_type
);


create or replace function seed.select_assortment(assortment_name text, oid integer)
returns integer as $$
  select a.id from public.assortments a where a.name = assortment_name and organization_id = oid;
$$ language sql;


create or replace function seed.select_location(location_name text, oid integer)
returns integer as $$
  select l.id from public.location l where l.name = location_name and organisation_id = oid;
$$ language sql;


create or replace function seed.select_cargo_unit(cargo_unit_name text)
returns integer as $$
  select cu.id from public.cargo_units cu where cu.name = cargo_unit_name;
$$ language sql;


create or replace function seed.select_country(country_name text)
returns integer as $$
  select c.numeric from public.countries c where c.english = country_name;
$$ language sql;


create or replace function seed.activate_user(uid integer)
returns void as $$
begin
  update private.user_account set activated = true, verified = true where user_account.user_id = uid;
end;
$$ language plpgsql;

create or replace function seed.select_vessel(vessel_imo integer)
returns integer as $$
  select vi.id from public.vessel_info vi where vi.imo = vessel_imo;
$$ language sql;


create or replace function seed.select_vessel_name(vessel_name text, oid integer)
returns integer as $$
  select vi.id
  from public.vessel_info vi
  join public.ships s on s.vessel_info_id = vi.id
  where lower(s.name) = lower(vessel_name)
  and s.organization_id = oid;
$$ language sql;


create or replace function seed.select_classification_society(society_name text)
returns integer as $$
  select cs.id from public.classification_society cs where cs.name = society_name;
$$ language sql;


create or replace function seed.create_email(username text, domain text)
returns text as $$
  select concat(lower(username), '@', lower(domain));
$$ language sql;


create or replace function seed.seed_organisation(organisation_name text, organisation_domain text)
returns integer as $$
declare
  oid integer;
begin
    insert into public.organizations (name, domain, email, mail_backup) values
      (organisation_name, organisation_domain, concat('organization@', organisation_domain), concat('backup@', organisation_domain))
      returning * into oid;

    return oid;
end;
$$ language plpgsql;


create or replace function seed.seed_user(oid integer, user_type public.user_type, name text, username text, user_password text, is_admin boolean)
returns seed.user_account as $$
declare
  user_data         public.users;
  organisation_data public.organizations;
begin
  select * into organisation_data from public.organizations where id = oid;

  select * into user_data
  from public.register_user(name, seed.create_email(username, organisation_data.domain), user_password, user_type, null, null, null);

  perform seed.activate_user(user_data.id);

  if is_admin is true then
    insert into user_rights (user_id, organization_id, org_admin, create_and_edit_orders, create_and_edit_voyages,
                           create_and_edit_contracts, access_financial_data)
    values (user_data.id, oid, true, true, true, true, true);
  end if;

  return (user_data.id, seed.create_email(username, organisation_data.domain), user_password, user_type)::seed.user_account;
end;
$$ language plpgsql;


create or replace function seed.seed_locations(oid int)
returns void as $$
begin
  insert into public.location (name, locode, latitude, longitude, country_id, organisation_id) values
    ('Porvoo', 'PRV', 60.4, 25.66666667, (select numeric from public.countries where english = 'Finland'), oid),
    ('Naantali', 'NLI', 60.45, 22.03333333, (select numeric from public.countries where english = 'Finland'), oid),
    ('Vaasa', 'VAA', 63.1, 21.6, (select numeric from public.countries where english = 'Finland'), oid),
    ('Pori', 'POR', 61.48333333, 21.8, (select numeric from public.countries where english = 'Finland'), oid),
    ('Hamina', 'HMN', 60.56666667, 27.2, (select numeric from public.countries where english = 'Finland'), oid),
    ('Kemi', 'KEM', 65.73333333, 24.56666667, (select numeric from public.countries where english = 'Finland'), oid),
    ('Kokkola', 'KOK', 63.83333333, 23.11666667, (select numeric from public.countries where english = 'Finland'), oid),
    ('Västerås', 'VST', 59.61666667, 16.55, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Stockholm', 'STO', 59.33333333, 18.05, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Luleå', 'LLA', 65.58333333, 22.15, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Kalmar', 'KLR', 56.66166687, 16.37166595, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Holmsund', 'HLD', 63.69, 20.343, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Sundsvall', 'SDL', 62.38833237, 17.34749985, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Muuga', 'MUG', 59.5, 24.96666667, (select numeric from public.countries where english = 'Estonia'), oid),
    ('Riga', 'RIX', 56.98166656, 24.09166718, (select numeric from public.countries where english = 'Latvia'), oid),
    ('Klaipeda', 'KLJ', 55.6865, 21.132, (select numeric from public.countries where english = 'Lithuania'), oid),
    ('St Petersburg', 'LED', 59.91933, 30.327035, (select numeric from public.countries where english = 'Russian Federation'), oid),
    ('Oskarshamn', 'OSK', 57.267, 16.468, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Swinoujscie', 'SWI', 53.9095, 14.2785, (select numeric from public.countries where english = 'Poland'), oid),
    ('Turku', 'TKU', 60.4385, 22.22697, (select numeric from public.countries where english = 'Finland'), oid),
    ('Gävle', 'GVX', 60.6865, 17.2, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Norrköping', 'NRK', 58.6175, 16.2235, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Piteå', 'PIT', 65.318025, 21.4971, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Södertälje', 'SOE', 59.18, 17.647, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Oulu', 'OUL', 65.0145, 25.43152, (select numeric from public.countries where english = 'Finland'), oid),
    ('Alesund', 'AES', 62.46833419799805, 6.150000095367432, (select numeric from public.countries where english = 'Norway'), oid),
    ('Bordeaux', 'BOD', 44.85333251953125, -0.5633333325386047, (select numeric from public.countries where english = 'France'), oid),
    ('Aalborg', 'AAL', 57.051666259765625, 9.928333282470703, (select numeric from public.countries where english = 'Denmark'), oid),
    ('Aarhus', 'AAR', 56.16166687011719, 10.238333702087402, (select numeric from public.countries where english = 'Denmark'), oid),
    ('Bilbao', 'BIO', 43.349998474121094, -3.0333330631256104, (select numeric from public.countries where english = 'Spain'), oid),
    ('Borsele', 'BOR', 51.40999984741211, 3.7266664505004883, (select numeric from public.countries where english = 'Netherlands'), oid),
    ('Amsterdam', 'AMS', 52.404998779296875, 4.87666654586792, (select numeric from public.countries where english = 'Netherlands'), oid),
    ('Antwerp', 'ANR', 51.3466682434082, 4.269999980926514, (select numeric from public.countries where english = 'Belgium'), oid),
    ('Bergen', 'BGO', 60.391666412353516, 5.303333282470703, (select numeric from public.countries where english = 'Norway'), oid),
    ('Bodo', 'BOO', 67.28666687011719, 14.375, (select numeric from public.countries where english = 'Norway'), oid),
    ('Bremen', 'BRE', 53.119998931884766, 8.704999923706055, (select numeric from public.countries where english = 'Germany'), oid),
    ('Butinge Marine Terminal', 'BOT', 56.04499816894531, 20.961666107177734, (select numeric from public.countries where english = 'Lithuania'), oid),
    ('Brofjorden', 'BRO', 58.356666564941406, 11.438333511352539, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Donges', 'DON', 47.30416488647461, -2.066666603088379, (select numeric from public.countries where english = 'France'), oid),
    ('Fawley', 'FAW', 50.84166717529297, -1.3300000429153442, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Flotta Terminal', 'FLH', 58.8466682434082, -3.116666555404663, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Gdansk', 'GDN', 54.38166809082031, 18.65833282470703, (select numeric from public.countries where english = 'Poland'), oid),
    ('Copenhagen', 'CPH', 55.7066650390625, 12.608333587646484, (select numeric from public.countries where english = 'Denmark'), oid),
    ('Fredericia', 'FRC', 55.5533332824707, 9.75, (select numeric from public.countries where english = 'Denmark'), oid),
    ('Gdynia', 'GDY', 54.53499984741211, 18.543333053588867, (select numeric from public.countries where english = 'Poland'), oid),
    ('Halmstad', 'HAD', 56.65083312988281, 12.837499618530273, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Gulfhavn', 'GFH', 55.204166412353516, 11.241666793823242, (select numeric from public.countries where english = 'Denmark'), oid),
    ('Gothenburg', 'GOT', 57.70166778564453, 11.931666374206543, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Harstad', 'HRD', 68.80166625976562, 16.549999237060547, (select numeric from public.countries where english = 'Norway'), oid),
    ('Hamburg', 'HAM', 53.54166793823242, 9.931666374206543, (select numeric from public.countries where english = 'Germany'), oid),
    ('Haugesund', 'HAU', 59.42166519165039, 5.245833396911621, (select numeric from public.countries where english = 'Norway'), oid),
    ('Inkoo', 'INK', 60.008331298828125, 23.963333129882812, (select numeric from public.countries where english = 'Finland'), oid),
    ('Helsingborg', 'HEL', 56.02666473388672, 12.691666603088379, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Hernosund', 'HND', 62.643333435058594, 17.945833206176758, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Immingham Oil Terminal', 'IMM', 53.63249969482422, -0.164166659116745, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Hound Point', 'HPT', 56.0099983215332, -3.363333225250244, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Kaliningrad', 'KGD', 54.70333480834961, 20.453332901000977, (select numeric from public.countries where english = 'Russian Federation'), oid),
    ('Helsinki', 'HEL', 60.14833450317383, 24.913333892822266, (select numeric from public.countries where english = 'Finland'), oid),
    ('Kalundborg', 'KAL', 55.67499923706055, 11.09333324432373, (select numeric from public.countries where english = 'Denmark'), oid),
    ('Koping', 'KOG', 59.50166702270508, 16.02166748046875, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Kotka', 'KTK', 60.448333740234375, 26.93166732788086, (select numeric from public.countries where english = 'Finland'), oid),
    ('La Coruna', 'LCG', 43.36000061035156, -8.376667022705078, (select numeric from public.countries where english = 'Spain'), oid),
    ('Kirkenes', 'KKN', 69.73500061035156, 30.059999465942383, (select numeric from public.countries where english = 'Norway'), oid),
    ('Leixoes', 'LEI', 41.18166732788086, -8.706666946411133, (select numeric from public.countries where english = 'Portugal'), oid),
    ('Kristiansand S.', 'KRS', 58.14250183105469, 7.989166736602783, (select numeric from public.countries where english = 'Norway'), oid),
    ('Malmo', 'MMA', 55.619998931884766, 12.986666679382324, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Liepaja', 'LPX', 56.525001525878906, 20.985000610351562, (select numeric from public.countries where english = 'Latvia'), oid),
    ('Mongstad', 'MON', 60.81666564941406, 5.041666507720947, (select numeric from public.countries where english = 'Norway'), oid),
    ('Milford Haven', 'MLF', 51.698333740234375, -5.053333282470703, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Oslo', 'OSL', 59.90416717529297, 10.749166488647461, (select numeric from public.countries where english = 'Norway'), oid),
    ('Nynashamn', 'NYN', 58.91666793823242, 17.969999313354492, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Pietarsaari', 'PRS', 63.7167824, 22.688509, (select numeric from public.countries where english = 'Finland'), oid),
    ('Rauma', 'RAU', 61.125, 21.440000534057617, (select numeric from public.countries where english = 'Norway'), oid),
    ('Primorsk', 'PRI', 60.33000183105469, 28.700000762939453, (select numeric from public.countries where english = 'Russian Federation'), oid),
    ('Rostock', 'RSK', 54.15833282470703, 12.103333473205566, (select numeric from public.countries where english = 'Germany'), oid),
    ('Sillamae', 'SLM', 59.42499923706055, 27.741666793823242, (select numeric from public.countries where english = 'Estonia'), oid),
    ('Rotterdam', 'RTM', 51.901668548583984, 4.434999942779541, (select numeric from public.countries where english = 'Netherlands'), oid),
    ('Ornskoldsvik', 'OER', 63.28166580200195, 18.729999542236328, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Slagen', 'SLG', 59.32833480834961, 10.518333435058594, (select numeric from public.countries where english = 'Norway'), oid),
    ('Stavanger', 'SVG', 58.9716682434082, 5.764999866485596, (select numeric from public.countries where english = 'Norway'), oid),
    ('Skelleftehamn', 'SKE', 64.67832946777344, 21.272499084472656, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Stettin', 'SZZ', 53.442501068115234, 14.584166526794434, (select numeric from public.countries where english = 'Poland'), oid),
    ('Soderhamn', 'SOO', 61.311668395996094, 17.08916664123535, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Sullom Voe', 'SUL', 60.45833206176758, -1.3016666173934937, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Sture', 'STU', 60.62333297729492, 4.860000133514404, (select numeric from public.countries where english = 'Norway'), oid),
    ('Thamesport', 'THP', 51.42916488647461, 0.6850000023841858, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Teesport', 'TEE', 54.606666564941406, -1.159999966621399, (select numeric from public.countries where english = 'United Kingdom of Great Britain and Northern Ireland'), oid),
    ('Paldiski South Harbour', 'PLN', 59.33333206176758, 24.08333396911621, (select numeric from public.countries where english = 'Estonia'), oid),
    ('Tromso', 'TOS', 69.64666748046875, 18.968334197998047, (select numeric from public.countries where english = 'Norway'), oid),
    ('Umea', 'UME', 63.6966667175293, 20.343334197998047, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Trondheim', 'TRD', 63.44166564941406, 10.41333293914795, (select numeric from public.countries where english = 'Norway'), oid),
    ('Ventspils', 'VNT', 57.4033317565918, 21.53499984741211, (select numeric from public.countries where english = 'Latvia'), oid),
    ('Ust Luga', 'ULU', 59.68600082397461, 28.417667388916016, (select numeric from public.countries where english = 'Russian Federation'), oid),
    ('Wilhelmshaven', 'WVN', 53.53333282470703, 8.16333293914795, (select numeric from public.countries where english = 'Germany'), oid),
    ('Vysotsk', 'VYS', 60.621665954589844, 28.55500030517578, (select numeric from public.countries where english = 'Russian Federation'), oid),
    ('Vastervik', 'VVK', 57.760833740234375, 16.649999618530273, (select numeric from public.countries where english = 'Sweden'), oid),
    ('Dunkirk', 'IRK', 51.05666732788086, 2.3499999046325684, (select numeric from public.countries where english = 'France'), oid)
    on conflict do nothing;
end;
$$ language plpgsql;


create or replace function seed.seed_assortments(oid int)
returns void as $$
begin
  insert into public.assortments (name, user_id, charterer_org_id, organization_id, specific_gravity) values
    ('NRD []', null, oid, oid, 0.8),
    ('Diesel', null, oid, oid, 0.8),
    ('DRP-29/38 [560217]', null, oid, oid, 0.8),
    ('DIPRO-12 [560185]', null, oid, oid, 0.8),
    ('BE95E10BS [560895]', null, oid, oid, 0.8),
    ('Mogas', null, oid, oid, 0.8),
    ('DI-15PARA [560193]', null, oid, oid, 0.8),
    ('DI-0PARA [560189]', null, oid, oid, 0.8),
    ('MDODMB [560305]', null, oid, oid, 0.8),
    ('DI2R [560106]', null, oid, oid, 0.8),
    ('MO93SEB [560326]', null, oid, oid, 0.8),
    ('BE95E10BI [560334]', null, oid, oid, 0.8),
    ('GO4SE [560236]', null, oid, oid, 0.8),
    ('DI5R [560125]', null, oid, oid, 0.8),
    ('DI0RBA [560838]', null, oid, oid, 0.8),
    ('DI0RBAB [560086]', null, oid, oid, 0.8),
    ('HSSR', null, oid, oid, 0.8),
    ('BE98E5KL [560035]', null, oid, oid, 0.8),
    ('RMBSWE [560484]', null, oid, oid, 0.8),
    ('JET', null, oid, oid, 0.8),
    ('KATZ [560268]', null, oid, oid, 0.8),
    ('MO93SEBOB [560327]', null, oid, oid, 0.8),
    ('NRD-15C [560998]', null, oid, oid, 0.8),
    ('DI4RBA-16 [560816]', null, oid, oid, 0.8),
    ('BE95E10KL [560022]', null, oid, oid, 0.8),
    ('MO98EE [560346]', null, oid, oid, 0.8),
    ('DIR-0/7 [560188]', null, oid, oid, 0.8),
    ('DIRP-5/15 [560212]', null, oid, oid, 0.8),
    ('DIR-29/38 [560200]', null, oid, oid, 0.8),
    ('JET A-1 [560260]', null, oid, oid, 0.8)
    on conflict do nothing;
end;
$$ language plpgsql;


create or replace function seed.seed_classification_society()
returns void as $$
begin
  insert into public.classification_society (name) values
    ('Lloyd''s Register'),
    ('Bureau Veritas'),
    ('Croatian Register of Shipping'),
    ('Registro Italiano Navale'),
    ('American Bureau of Shipping'),
    ('DNV GL'),
    ('Nippon Kaiji Kyokai'),
    ('Russian Maritime Register of Shipping'),
    ('Polish Register of Shipping'),
    ('China Classification Society'),
    ('Korean Register of Shipping'),
    ('Indian Register of Shipping')
    on conflict do nothing;
end;
$$ language plpgsql;


create or replace function seed.seed_ice_class()
returns void as $$
begin
  insert into public.ice_class (name) values
    ('IA Super'),
    ('IA'),
    ('IB'),
    ('IC'),
    ('Category II')
    on conflict do nothing;
end;
$$ language plpgsql;


create or replace function seed.seed_vessels(oid integer)
returns void as $$
begin
  insert into public.vessel_info (imo, mmsi, owner_organisation_id, year, flag, call_sign, loa, breadth, draft, loading_rate, loading_unit, discharging_rate, discharging_unit) values
    (9267560, 230957000, oid, 2005, 1, 'OJKZ', 139.75, 21.75, 9.02, 245, 'metric_tonnes_per_hour', 285, 'metric_tonnes_per_hour'),
    (9808259, 257037140, oid, 2018, 1, 'LAEK8', 153.93, 23.87, 9.74, 224, 'metric_tonnes_per_hour', 252, 'metric_tonnes_per_hour'),
    (9808261, 257037270, oid, 2018, 1, 'LAEL8', 153.96, 23.75, 9.74, 231, 'metric_tonnes_per_hour', 260, 'metric_tonnes_per_hour'),
    (9321615, 266471000, oid, 2006, 1, 'SBGJ', 124.5, 18.1, 6.4, 280, 'metric_tonnes_per_hour', 323, 'metric_tonnes_per_hour'),
    (9267558, 230956000, oid, 2004, 1, 'OJKY', 139.75, 21.75, 9.02, 284, 'metric_tonnes_per_hour', 305, 'metric_tonnes_per_hour'),
    (9378723, 259768000, oid, 2008, 1, 'LADP7', 144.19, 23.2, 8.89, 272, 'metric_tonnes_per_hour', 307, 'metric_tonnes_per_hour'),
    (9378735, 259769000, oid, 2008, 1, 'LAEF7', 144.1, 23.2, 8.89, 435, 'metric_tonnes_per_hour', 428, 'metric_tonnes_per_hour')
    on conflict do nothing;

  insert into public.ships (name, organization_id, weight_capacity, weight_capacity_type, air_draft, speed_laden, consumption_laden, consumption_port, tc_rate, vessel_info_id, mass_capacity, mass_unit, volume_capacity, volume_unit) values
    ('SUULA', oid, 14750, 'dwt', 32.74, 12.5, 22, 3.8, 15603, seed.select_vessel(9267560), 14750, 'tonne', 15734, 'm^3'),
    ('EK RIVER', oid, 19884, 'dwt', 33.9, 11, 13, 4.5, 14300, seed.select_vessel(9808259), 19884, 'tonne', 22020, 'm^3'),
    ('EK STREAM', oid, 19881, 'dwt', 33.91, 11, 13, 4.5, 14300, seed.select_vessel(9808261), 19881, 'tonne', 22030, 'm^3'),
    ('TELLUS', oid, 9181, 'dwt', 32, 12.5, 12, 3.5, 11250, seed.select_vessel(9321615), 9181, 'tonne', 10422, 'm^3'),
    ('KIISLA', oid, 14750, 'dwt', 32.74, 12.5, 18, 3.8, 15614, seed.select_vessel(9267558), 14750, 'tonne', 15761, 'm^3'),
    ('STEN SUOMI', oid, 16619, 'dwt', 35.9, 11, 15, 4.5, 12750, seed.select_vessel(9378723), 16619, 'tonne', 18478, 'm^3'),
    ('STEN BOTHNIA', oid, 16611, 'dwt', 39, 11, 15, 4.5, 12750, seed.select_vessel(9378735), 16611, 'tonne', 18478, 'm^3')
    on conflict do nothing;
end;
$$ language plpgsql;


create or replace function seed.seed_vessel_holds(oid integer)
returns void as $$
begin
  insert into public.vessel_hold (hold, name, min_volume, max_volume, cleaning_cost, type, length, width, height, position_length, position_width, position_height, organisation_id, vessel_id) values
    (1, '1P', 0, 1228, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (2, '1S', 0, 1222, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (3, '2P/S', 0, 3700, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (4, '2P/S', 0, 3879, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (5, '4P', 0, 2130, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (6, '5S', 0, 2123, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (7, '5P/S', 0, 3736, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (8, '6P/S', 0, 4004, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (9, 'SLOP P/S', 0, 335, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK RIVER', oid)),
    (1, '1P', 0, 1227, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (2, '1S', 0, 1221, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (3, '2P/S', 0, 3702, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (4, '2P/S', 0, 3884, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (5, '4P', 0, 2131, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (6, '5S', 0, 2124, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (7, '5P/S', 0, 3736, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (8, '6P/S', 0, 4003, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (9, 'SLOP P/S', 0, 336, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('EK STREAM', oid)),
    (1, '1P/S', 0, 2076, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (2, '2P/S', 0, 3373, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (3, '3P/S', 0, 3534, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (4, '4P/S', 0, 3537, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (5, '5P/S', 0, 3537, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (6, '6P/S', 0, 2421, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (7, 'SLOP P/S', 0, 544, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN BOTHNIA', oid)),
    (1, '1P/S', 0, 2076, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (2, '2P/S', 0, 3373, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (3, '3P/S', 0, 3534, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (4, '4P/S', 0, 3537, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (5, '5P/S', 0, 3537, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (6, '6P/S', 0, 2421, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (7, 'SLOP P/S', 0, 560, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('STEN SUOMI', oid)),
    (1, '1P/S', 0, 2377, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (2, '2P/S', 0, 2252, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (3, '3P/S', 0, 3260, 0, 'liquid', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (4, '4P/S', 0, 1863, 0, 'liquid', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (5, '5P/S', 0, 1864, 0, 'liquid', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (6, '6P/S', 0, 3261, 0, 'liquid', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (7, 'SLOP P/S', 0, 884, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('KIISLA', oid)),
    (1, '1P/S', 0, 2372, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (2, '2P/S', 0, 2248, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (3, '3P/S', 0, 3259, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (4, '4P/S', 0, 1864, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (5, '5P/S', 0, 1858, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (6, '6P/S', 0, 3253, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (7, 'SLOP P/S', 0, 880, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('SUULA', oid)),
    (1, '1C', 0, 998, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('TELLUS', oid)),
    (2, '2P/S', 0, 1843, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('TELLUS', oid)),
    (3, '3P/S', 0, 2048, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('TELLUS', oid)),
    (4, '4P/S', 0, 2048, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('TELLUS', oid)),
    (5, '5P/S', 0, 2047, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('TELLUS', oid)),
    (6, '6P/S', 0, 1438, 0, 'hold', 0, 0, 0, 0, 0, 0, oid, seed.select_vessel_name('TELLUS', oid))
    on conflict do nothing;
end;
$$ language plpgsql;


create or replace function seed.seed_orders(uid int, oid int)
returns void as $$
begin
  insert into public.orders (user_id, charterer_organization_id, load_port_id, discharge_port_id, rta, cargo_amount, assortment_id, margin_amount, margin_unit, specific_gravity, layday, cancelling, loading_rate, discharging_rate, loading_unit, discharging_unit, loading_days, discharging_days, cargo_unit_id, delivered_before) values
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-09-25 00:00:00+00', 1000, seed.select_assortment('NRD []', oid), 0, 'MINMAX', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-27 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Sundsvall', oid), '2020-09-21 00:00:00+00', 1800, seed.select_assortment('GO4SE [560236]', oid), 10, 'PERCENTAGE', 0.8, '2020-09-20 00:00:00+00', '2020-09-22 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-26 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Sundsvall', oid), '2020-09-21 00:00:00+00', 2730, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-09-20 00:00:00+00', '2020-09-22 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), '2020-09-26 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Sundsvall', oid), '2020-09-21 00:00:00+00', 7000, seed.select_assortment('DI5R [560125]', oid), 10, 'PERCENTAGE', 0.8, '2020-09-20 00:00:00+00', '2020-09-22 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-26 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-09-23 00:00:00+00', 18600, seed.select_assortment('Mogas', oid), 5, 'PERCENTAGE', 0.8, '2020-09-20 00:00:00+00', '2020-09-22 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-25 00:00:00+00'),
    (uid, oid, seed.select_location('Naantali', oid), seed.select_location('Riga', oid), '2020-09-25 00:00:00+00', 2000, seed.select_assortment('DI0RBA [560838]', oid), 0, 'MINMAX', 0.8, '2020-09-21 00:00:00+00', '2020-09-23 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-27 00:00:00+00'),
    (uid, oid, seed.select_location('Naantali', oid), seed.select_location('Riga', oid), '2020-09-25 00:00:00+00', 8000, seed.select_assortment('DI0RBAB [560086]', oid), 0, 'MINMAX', 0.8, '2020-09-21 00:00:00+00', '2020-09-23 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-27 00:00:00+00'),
    (uid, oid, seed.select_location('St Petersburg', oid), seed.select_location('Muuga', oid), null, 10000, seed.select_assortment('JET', oid), 5, 'PERCENTAGE', 0.8, '2020-09-21 00:00:00+00', '2020-09-25 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), null),
    (uid, oid, seed.select_location('St Petersburg', oid), seed.select_location('Porvoo', oid), null, 7000, seed.select_assortment('HSSR', oid), 5, 'PERCENTAGE', 0.8, '2020-09-21 00:00:00+00', '2020-09-25 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), null, 18600, seed.select_assortment('Mogas', oid), 5, 'PERCENTAGE', 0.8, '2020-09-22 00:00:00+00', '2020-09-24 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Holmsund', oid), null, 6500, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-09-24 00:00:00+00', '2020-09-26 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Holmsund', oid), null, 11700, seed.select_assortment('DI5R [560125]', oid), 0, 'MINMAX', 0.8, '2020-09-24 00:00:00+00', '2020-09-26 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Swinoujscie', oid), '2020-09-27 00:00:00+00', 14000, seed.select_assortment('Diesel', oid), 0, 'MINMAX', 0.8, '2020-09-24 00:00:00+00', '2020-09-26 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), '2020-10-02 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-09-28 00:00:00+00', 12000, seed.select_assortment('DI4RBA-16 [560816]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-25 00:00:00+00', '2020-09-27 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), '2020-09-30 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Stockholm', oid), '2020-09-27 00:00:00+00', 5000, seed.select_assortment('DI5R [560125]', oid), 0, 'MINMAX', 0.8, '2020-09-25 00:00:00+00', '2020-09-27 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Stockholm', oid), '2020-09-27 00:00:00+00', 13000, seed.select_assortment('MO93SEBOB [560327]', oid), 0, 'MINMAX', 0.8, '2020-09-25 00:00:00+00', '2020-09-27 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Västerås', oid), '2020-09-28 00:00:00+00', 7000, seed.select_assortment('MO93SEB [560326]', oid), 0, 'MINMAX', 0.8, '2020-09-25 00:00:00+00', '2020-09-27 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Södertälje', oid), '2020-09-28 00:00:00+00', 3000, seed.select_assortment('RMBSWE [560484]', oid), 0, 'MINMAX', 0.8, '2020-09-25 00:00:00+00', '2020-09-27 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Pori', oid), '2020-10-01 00:00:00+00', 7850, seed.select_assortment('DIRP-5/15 [560212]', oid), 0, 'MINMAX', 0.8, '2020-09-27 00:00:00+00', '2020-09-29 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-05 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Vaasa', oid), '2020-10-01 00:00:00+00', 7850, seed.select_assortment('DIRP-5/15 [560212]', oid), 0, 'MINMAX', 0.8, '2020-09-27 00:00:00+00', '2020-09-29 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-05 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Klaipeda', oid), '2020-10-01 00:00:00+00', 1200, seed.select_assortment('MO98EE [560346]', oid), 0, 'MINMAX', 0.8, '2020-09-27 00:00:00+00', '2020-09-29 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Klaipeda', oid), null, 7500, seed.select_assortment('DI0RBA [560838]', oid), 0, 'MINMAX', 0.8, '2020-09-27 00:00:00+00', '2020-09-29 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Klaipeda', oid), null, 5000, seed.select_assortment('BE95E10BI [560334]', oid), 0, 'MINMAX', 0.8, '2020-09-27 00:00:00+00', '2020-09-29 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Västerås', oid), '2020-10-01 00:00:00+00', 3000, seed.select_assortment('DI5R [560125]', oid), 10, 'PERCENTAGE', 0.8, '2020-09-28 00:00:00+00', '2020-09-30 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-06 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Västerås', oid), null, 3510, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-09-28 00:00:00+00', '2020-09-30 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 8600, seed.select_assortment('DI-0PARA [560189]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-29 00:00:00+00', '2020-10-01 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 7200, seed.select_assortment('DIR-29/38 [560200]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-29 00:00:00+00', '2020-10-01 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kemi', oid), null, 6000, seed.select_assortment('DI-0PARA [560189]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-29 00:00:00+00', '2020-10-01 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-10-01 00:00:00+00', 1300, seed.select_assortment('BE95E10KL [560022]', oid), 0, 'MINMAX', 0.8, '2020-09-29 00:00:00+00', '2020-10-01 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Oskarshamn', oid), '2020-09-18 00:00:00+00', 15500, seed.select_assortment('DI2R [560106]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-14 00:00:00+00', '2020-09-16 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), '2020-09-22 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Sundsvall', oid), '2020-09-18 00:00:00+00', 13245, seed.select_assortment('MO93SEBOB [560327]', oid), 10, 'PERCENTAGE', 0.8, '2020-09-14 00:00:00+00', '2020-09-16 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-22 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Södertälje', oid), '2020-09-21 00:00:00+00', 3000, seed.select_assortment('RMBSWE [560484]', oid), 0, 'MINMAX', 0.8, '2020-09-15 00:00:00+00', '2020-09-17 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-22 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Södertälje', oid), '2020-09-21 00:00:00+00', 6000, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-09-15 00:00:00+00', '2020-09-17 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-22 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Gävle', oid), null, 3120, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-10-02 00:00:00+00', '2020-10-04 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), null),
    (uid, oid, seed.select_location('Naantali', oid), seed.select_location('Riga', oid), '2020-10-07 00:00:00+00', 3100, seed.select_assortment('BE95E10BS [560895]', oid), 0, 'MINMAX', 0.8, '2020-10-04 00:00:00+00', '2020-10-06 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-09 00:00:00+00'),
    (uid, oid, seed.select_location('Naantali', oid), seed.select_location('Riga', oid), '2020-10-07 00:00:00+00', 7800, seed.select_assortment('DI0RBAB [560086]', oid), 0, 'MINMAX', 0.8, '2020-10-04 00:00:00+00', '2020-10-06 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-09 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Naantali', oid), null, 3900, seed.select_assortment('KATZ [560268]', oid), 0, 'PERCENTAGE', 0.8, '2020-10-04 00:00:00+00', '2020-10-06 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Naantali', oid), null, 6500, seed.select_assortment('DIR-0/7 [560188]', oid), 0, 'PERCENTAGE', 0.8, '2020-10-04 00:00:00+00', '2020-10-06 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Naantali', oid), null, 6300, seed.select_assortment('DI-15PARA [560193]', oid), 0, 'PERCENTAGE', 0.8, '2020-10-07 00:00:00+00', '2020-10-09 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Naantali', oid), null, 4100, seed.select_assortment('MDODMB [560305]', oid), 0, 'PERCENTAGE', 0.8, '2020-10-07 00:00:00+00', '2020-10-09 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Södertälje', oid), '2020-09-21 00:00:00+00', 1100, seed.select_assortment('MDODMB [560305]', oid), 0, 'MINMAX', 0.8, '2020-09-15 00:00:00+00', '2020-09-17 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-22 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Hamina', oid), '2020-09-16 00:00:00+00', 5300, seed.select_assortment('DRP-29/38 [560217]', oid), 0, 'MINMAX', 0.8, '2020-09-15 00:00:00+00', '2020-09-17 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-23 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Hamina', oid), '2020-09-16 00:00:00+00', 3000, seed.select_assortment('DIRP-5/15 [560212]', oid), 0, 'MINMAX', 0.8, '2020-09-15 00:00:00+00', '2020-09-17 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-23 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Turku', oid), null, 3500, seed.select_assortment('BE95E10KL [560022]', oid), 0, 'MINMAX', 0.8, '2020-09-17 00:00:00+00', '2020-09-19 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Turku', oid), null, 2500, seed.select_assortment('BE98E5KL [560035]', oid), 0, 'MINMAX', 0.8, '2020-09-17 00:00:00+00', '2020-09-19 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Naantali', oid), null, 3900, seed.select_assortment('MDODMB [560305]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-17 00:00:00+00', '2020-09-19 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Luleå', oid), '2020-09-22 00:00:00+00', 12000, seed.select_assortment('DI5R [560125]', oid), 0, 'MINMAX', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), '2020-10-02 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Vaasa', oid), null, 1800, seed.select_assortment('DIR-29/38 [560200]', oid), 0, 'MINMAX', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Vaasa', oid), null, 3000, seed.select_assortment('DI-0PARA [560189]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Vaasa', oid), null, 3600, seed.select_assortment('DIR-0/7 [560188]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-09-25 00:00:00+00', 3000, seed.select_assortment('MO98EE [560346]', oid), 0, 'MINMAX', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-27 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-09-25 00:00:00+00', 4000, seed.select_assortment('DI0RBA [560838]', oid), 0, 'MINMAX', 0.8, '2020-09-19 00:00:00+00', '2020-09-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-09-27 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Holmsund', oid), '2020-10-09 00:00:00+00', 9000, seed.select_assortment('DI5R [560125]', oid), 0, 'MINMAX', 0.8, '2020-10-07 00:00:00+00', '2020-10-09 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-15 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Muuga', oid), '2020-10-01 00:00:00+00', 4000, seed.select_assortment('DI0RBA [560838]', oid), 0, 'MINMAX', 0.8, '2020-09-29 00:00:00+00', '2020-10-01 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-03 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Oulu', oid), null, 4000, seed.select_assortment('DI-0PARA [560189]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-30 00:00:00+00', '2020-10-02 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Oulu', oid), null, 5500, seed.select_assortment('DIR-0/7 [560188]', oid), 5, 'PERCENTAGE', 0.8, '2020-09-30 00:00:00+00', '2020-10-02 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Piteå', oid), '2020-10-02 00:00:00+00', 3900, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-10-01 00:00:00+00', '2020-10-03 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('t'), '2020-10-10 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Luleå', oid), '2020-10-05 00:00:00+00', 15700, seed.select_assortment('DI5R [560125]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-01 00:00:00+00', '2020-10-03 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-10 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 18700, seed.select_assortment('DIR-29/38 [560200]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-01 00:00:00+00', '2020-10-03 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Västerås', oid), '2020-10-02 00:00:00+00', 3000, seed.select_assortment('DI5R [560125]', oid), 10, 'PERCENTAGE', 0.8, '2020-10-01 00:00:00+00', '2020-10-03 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-07 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Västerås', oid), '2020-10-02 00:00:00+00', 4000, seed.select_assortment('MO93SEBOB [560327]', oid), 10, 'PERCENTAGE', 0.8, '2020-10-01 00:00:00+00', '2020-10-03 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-07 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kemi', oid), null, 10000, seed.select_assortment('JET A-1 [560260]', oid), 0, 'PERCENTAGE', 0.8, '2020-10-02 00:00:00+00', '2020-10-04 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Holmsund', oid), '2020-10-09 00:00:00+00', 4000, seed.select_assortment('MO93SEBOB [560327]', oid), 0, 'MINMAX', 0.8, '2020-10-07 00:00:00+00', '2020-10-09 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-15 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Norrköping', oid), '2020-10-10 00:00:00+00', 12200, seed.select_assortment('MO93SEB [560326]', oid), 0, 'MINMAX', 0.8, '2020-10-08 00:00:00+00', '2020-10-10 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-15 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 5000, seed.select_assortment('MDODMB [560305]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-11 00:00:00+00', '2020-10-13 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 10000, seed.select_assortment('DIR-0/7 [560188]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-11 00:00:00+00', '2020-10-13 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Södertälje', oid), '2020-10-14 00:00:00+00', 7000, seed.select_assortment('NRD-15C [560998]', oid), 0, 'MINMAX', 0.8, '2020-10-12 00:00:00+00', '2020-10-14 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-16 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Vaasa', oid), null, 4500, seed.select_assortment('DI-0PARA [560189]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-12 00:00:00+00', '2020-10-14 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Vaasa', oid), null, 5000, seed.select_assortment('DIR-0/7 [560188]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-12 00:00:00+00', '2020-10-14 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Sundsvall', oid), '2020-10-15 00:00:00+00', 1500, seed.select_assortment('GO4SE [560236]', oid), 10, 'PERCENTAGE', 0.8, '2020-10-12 00:00:00+00', '2020-10-14 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-20 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Sundsvall', oid), '2020-10-15 00:00:00+00', 6000, seed.select_assortment('DI5R [560125]', oid), 10, 'PERCENTAGE', 0.8, '2020-10-12 00:00:00+00', '2020-10-14 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-20 00:00:00+00'),
    (uid, oid, seed.select_location('Naantali', oid), seed.select_location('Riga', oid), '2020-10-18 00:00:00+00', 2000, seed.select_assortment('BE95E10BS [560895]', oid), 0, 'MINMAX', 0.8, '2020-10-12 00:00:00+00', '2020-10-14 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-20 00:00:00+00'),
    (uid, oid, seed.select_location('Naantali', oid), seed.select_location('Riga', oid), '2020-10-18 00:00:00+00', 7800, seed.select_assortment('DI0RBAB [560086]', oid), 0, 'MINMAX', 0.8, '2020-10-13 00:00:00+00', '2020-10-15 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-20 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Riga', oid), '2020-10-18 00:00:00+00', 3700, seed.select_assortment('DI0RBA [560838]', oid), 0, 'MINMAX', 0.8, '2020-10-14 00:00:00+00', '2020-10-16 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-20 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Riga', oid), '2020-10-18 00:00:00+00', 3500, seed.select_assortment('DIPRO-12 [560185]', oid), 0, 'MINMAX', 0.8, '2020-10-14 00:00:00+00', '2020-10-16 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), '2020-10-20 00:00:00+00'),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 1600, seed.select_assortment('BE98E5KL [560035]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-19 00:00:00+00', '2020-10-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 8000, seed.select_assortment('DI-0PARA [560189]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-19 00:00:00+00', '2020-10-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null),
    (uid, oid, seed.select_location('Porvoo', oid), seed.select_location('Kokkola', oid), null, 8000, seed.select_assortment('DIR-0/7 [560188]', oid), 5, 'PERCENTAGE', 0.8, '2020-10-19 00:00:00+00', '2020-10-21 00:00:00+00', 435, 428, 'metric_tonnes_per_hour', 'metric_tonnes_per_hour', '(f,f,f,f,f,t,t,t,"EX")', '(f,f,f,f,f,t,t,t,"EX")', seed.select_cargo_unit('m3'), null);
end;
$$ language plpgsql;


create or replace function seed.seed_data(oname text, odomain text)
returns void as $$
declare
  oid        integer;
  admin_user seed.user_account;
  ship_user  seed.user_account;
  port_user  seed.user_account;
begin
  select * into oid from seed.seed_organisation(oname, odomain);

  perform seed.seed_locations(oid);
  perform seed.seed_assortments(oid);
  perform seed.seed_vessels(oid);
  perform seed.seed_vessel_holds(oid);
  perform seed.seed_classification_society();
  perform seed.seed_ice_class();

  select * into admin_user from seed.seed_user(oid, 'cargo', 'Admin', 'admin', 'admin', true);
  select * into ship_user from seed.seed_user(oid, 'ship', 'Shipowner', 'shipowner', 'shipowner', false);
  select * into port_user from seed.seed_user(oid, 'port_agent', 'Port Agent', 'portagent', 'portagent', false);

  perform seed.seed_orders(admin_user.user_id, oid);
end;
$$ language plpgsql;


select * from seed.seed_data('Seaber', 'seaber.local');
select * from seed.seed_data('Testing', 'testing.local');


drop schema seed cascade;
commit;
