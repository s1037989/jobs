-- 1 up
create table if not exists jobs (
  id        serial primary key,
  name      text,
  contacted date,
  scheduled date,
  estimate  int,
  address   text,
  phone     text,
  description text,
  grinder   boolean,
  chipper   boolean
);

-- 1 down
drop table if exists jobs;
