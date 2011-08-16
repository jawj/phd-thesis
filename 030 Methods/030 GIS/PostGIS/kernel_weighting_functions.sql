-- kernel functions

create or replace function uniform_pdf
( double precision              -- $1 = x
, double precision default 1.0  -- $2 = bandwidth
, double precision default 0.0  -- $3 = centre
) returns double precision as $$
  select
    case
      when $1 > $3 - $2 and $1 < $3 + $2 then (
        select cast(0.5 as double precision)
      )
      else 0
    end;
$$ language sql immutable;

create or replace function triangular_pdf
( double precision              -- $1 = x
, double precision default 1.0  -- $2 = bandwidth
, double precision default 0.0  -- $3 = centre
) returns double precision as $$
  select
    case
      when $1 > $3 - $2 and $1 < $3 + $2 then (
        select 1 - abs(($1 - $3) / $2)
      )
      else 0
    end;
$$ language sql immutable;

create or replace function normal_pdf
( double precision              -- $1 = x
, double precision default 1.0  -- $2 = std dev (bandwidth)
, double precision default 0.0  -- $3 = mean (centre)
) returns double precision as $$
  select (1.0 / (sqrt(2.0 * pi() * pow($2, 2)))) 
       * exp(-pow($1 - $3, 2) / (2.0 * pow($2, 2)));
$$ language sql immutable;

create or replace function epanechnikov_pdf
( double precision              -- $1 = x
, double precision default 1.0  -- $2 = bandwidth
, double precision default 0.0  -- $3 = centre
) returns double precision as $$
  select
    case
      when $1 > $3 - $2 and $1 < $3 + $2 then (
        select 0.75 * (1 - pow(($1 - $3) / $2, 2))
      )
      else 0
    end;
$$ language sql immutable;


-- current kernel function 
-- (uncomment the kernel you want to use, and redefine: the normal is shown here)

create or replace function __current_kernel_pdf
( double precision              -- $1 = x
, double precision default 1.0  -- $2 = std dev/bandwidth
, double precision default 0.0  -- $3 = mean/centre
) returns double precision as $$
  select
    normal_pdf
    -- epanechnikov_pdf
    -- triangular_pdf
    -- uniform_pdf
    ($1, $2, $3);
$$ language sql immutable;


-- support functions

create or replace function __slice_height
( double precision  -- $1 = kernel std dev
, double precision  -- $2 = kernel radius at top of slice
, double precision  -- $3 = kernel radius at bottom of slice
) returns double precision as $$
  select __current_kernel_pdf($2, $1) - __current_kernel_pdf($3, $1);
$$ language sql immutable;

create or replace function __slice_radius
( double precision  -- $1 = kernel radius at top of slice
, double precision  -- $2 = kernel radius at bottom of slice
) returns double precision as $$
  select $1 + (($2 - $1) / 2);
$$ language sql immutable;

create or replace function __kernel_slice_volume
( double precision  -- $1 = kernel std dev
, double precision  -- $2 = kernel radius at top of slice
, double precision  -- $3 = kernel radius at bottom of slice
, int               -- $4 = buffer precision
) returns double precision as $$
  select
    coalesce(
      st_area(
        st_buffer(
          st_makepoint(0, 0),
          __slice_radius($2, $3),
          $4
        )
      ),
      0
    )
    * __slice_height($1, $2, $3);
$$ language sql immutable;

create or replace function __intersected_slice_volume
( geometry          -- $1 = area geometry
, geometry          -- $2 = kernel centre point geometry
, double precision  -- $3 = kernel std dev
, double precision  -- $4 = kernel radius at top of slice
, double precision  -- $5 = kernel radius at bottom of slice
, int               -- $6 = buffer precision
) returns double precision as $$
  select
    coalesce(
      st_area(
        st_intersection(
          $1,
          st_buffer(
            $2,
            __slice_radius($4, $5),
            $6
          )
        )
      ),
      0
    )
    * __slice_height($3, $4, $5);
$$ language sql immutable;


-- main function

create or replace function kernel_weighted_local_proportion
( geometry          -- $1 = area geometry
, geometry          -- $2 = kernel centre point geometry
, double precision  -- $3 = kernel std dev
, double precision  -- $4 = truncation bandwidth (for normal only -- for others, repeat $3)
, int               -- $5 = number of slices for approximation
, int               -- $6 = buffer precision (points per 1/4 circle)
) returns double precision as $$
  select
    sum(__intersected_slice_volume(
      $1, $2, $3,
      $4 * (cast(s as double precision) / $5),     -- kernel radius at top of slice
      $4 * (cast(s + 1 as double precision) / $5), -- kernel radius at bottom of slice
      $6
    ))
    /
    sum(__kernel_slice_volume(
      $3,
      $4 * (cast(s as double precision) / $5),     -- kernel radius at top of slice
      $4 * (cast(s + 1 as double precision) / $5), -- kernel radius at bottom of slice
      $6
    ))
  from generate_series(0, $5 - 1) s;
$$ language sql immutable;
