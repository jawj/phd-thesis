-- kernel functions

create or replace function uniform_pdf(double precision, double precision default 1.0, double precision default 0.0) returns double precision as $$
  -- $1 = x, $2 = bandwidth, $3 = centre
  select
  case
    when $1 > $3 - $2 and $1 < $3 + $2 then (
      select cast(0.5 as double precision)
    )
    else 0
  end;
$$ language sql immutable;

create or replace function triangular_pdf(double precision, double precision default 1.0, double precision default 0.0) returns double precision as $$
  -- $1 = x, $2 = bandwidth, $3 = centre
  select
  case
    when $1 > $3 - $2 and $1 < $3 + $2 then (
      select 1 - abs(($1 - $3) / $2)
    )
    else 0
  end;
$$ language sql immutable;

create or replace function normal_pdf(double precision, double precision default 1.0, double precision default 0.0) returns double precision as $$
  -- $1 = x, $2 = std dev (bandwidth), $3 = mean (centre)
  select   (1.0 / (sqrt(2.0 * pi() * pow($2, 2))))
         * exp( - pow($1 - $3, 2)
                / (2.0 * pow($2, 2)) );
$$ language sql immutable;

create or replace function epanechnikov_pdf(double precision, double precision default 1.0, double precision default 0.0) returns double precision as $$
  -- $1 = x, $2 = bandwidth, $3 = centre
  select
  case
    when $1 > $3 - $2 and $1 < $3 + $2 then (
      select 0.75 * (1 - pow(($1 - $3) / $2, 2))
    )
    else 0
  end;
$$ language sql immutable;


-- current kernel function (uncomment the kernel you want to use and redefine: the normal is shown here)

create or replace function __current_kernel_pdf(double precision, double precision default 1.0, double precision default 0.0) returns double precision as $$
  -- $1 = x, $2 = std dev/bandwidth, $3 = mean/centre
  select
  normal_pdf
  -- epanechnikov_pdf
  -- triangular_pdf
  -- uniform_pdf
  ($1, $2, $3);
$$ language sql immutable;


-- support functions

create or replace function __slice_height(double precision, double precision, double precision) returns double precision as $$
  -- $1 = kernel std dev, $2 = kernel radius at top of slice, $3 = kernel radius at bottom of slice
  select __current_kernel_pdf($2, $1) - __current_kernel_pdf($3, $1);
$$ language sql immutable;

create or replace function __slice_radius(double precision, double precision) returns double precision as $$
  -- $1 = kernel radius at top of slice, $2 = kernel radius at bottom of slice
  select $1 + (($2 - $1) / 2);
$$ language sql immutable;

create or replace function __kernel_slice_volume(double precision, double precision, double precision, int) returns double precision as $$
  -- $1 = kernel std dev, $2 = kernel radius at top of slice, $3 = kernel radius at bottom of slice, $4 = buffer precision
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

create or replace function __intersected_slice_volume(geometry, geometry, double precision, double precision, double precision, int) returns double precision as $$
  -- $1 = area geometry, $2 = kernel centre point geometry, $3 = kernel std dev,
  -- $4 = kernel radius at top of slice, $5 = kernel radius at bottom of slice, $6 = buffer precision
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

create or replace function kernel_weighted_local_proportion(geometry, geometry, double precision, double precision, int, int) returns double precision as $$
  -- $1 = area geometry, $2 = kernel centre point geometry, $3 = kernel std dev, $4 = truncation bandwidth (for normal kernel only -- for others, repeat $3)
  -- $5 = number of slices for approximation, $6 = buffer precision (points per 1/4 circle)
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
