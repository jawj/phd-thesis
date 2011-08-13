create or replace function 
  nnDistance( 
      nearTo                   geometry
    , initialDistance          real
    , distanceMultiplier       real 
    , maxPower                 integer
    , nearThings               text
    , nearThingsGeometryField  text)
returns double precision as $$
declare 
  i       integer;
  sql     text;
  result  double precision;
begin
  i := 0;
  while i <= maxPower loop
    sql := ' select st_distance($1, ' ||  quote_ident(nearThingsGeometryField) || ')'
        || ' from ' || quote_ident(nearThings)
        || ' where st_dwithin($1, ' || quote_ident(nearThingsGeometryField) || ', $2 * ($3 ^ $4))' 
        || ' order by st_distance($1, ' ||  quote_ident(nearThingsGeometryField) || ')'
        || ' limit 1';
    execute sql into result using 
        nearTo              -- $1
      , initialDistance     -- $2
      , distanceMultiplier  -- $3
      , i;                  -- $4
    if result is not null then return result; end if;
    i := i + 1;
  end loop;
  return null;
end
$$ language 'plpgsql' stable;