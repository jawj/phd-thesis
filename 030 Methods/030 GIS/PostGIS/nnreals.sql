create or replace function 
  nnReals(
      nearTo                   geometry
    , initialDistance          real
    , distanceMultiplier       real 
    , maxPower                 integer
    , nearThings               text
    , nearThingsGeometryField  text
    , nearThingsRealField      text
    , numWanted                integer)
returns setof real as $$
declare 
  i       integer;
  sql     text;
  enough  boolean;
begin
  i := 0;
  while i <= maxPower loop
    sql := ' select count(1) >= $5 from ' || quote_ident(nearThings)
        || ' where st_dwithin($1, ' ||  quote_ident(nearThingsGeometryField) || ', $2 * ($3 ^ $4))';
    execute sql into enough using 
        nearTo              -- $1
      , initialDistance     -- $2
      , distanceMultiplier  -- $3
      , i                   -- $4
      , numWanted;          -- $5
    if enough or i = maxPower then
      sql := ' select ' || quote_ident(nearThingsRealField) || ' from ' || quote_ident(nearThings)
          || ' where st_expand($1, $2 * ($3 ^ $4)) && ' || quote_ident(nearThingsGeometryField)
          || ' order by st_distance($1, ' ||  quote_ident(nearThingsGeometryField) || ')'
          || ' limit $5';
      return query execute sql using 
          nearTo              -- $1
        , initialDistance     -- $2
        , distanceMultiplier  -- $3
        , i                   -- $4
        , numWanted;          -- $5
      return;
    end if;
    i := i + 1;
  end loop;
end
$$ language 'plpgsql' stable;