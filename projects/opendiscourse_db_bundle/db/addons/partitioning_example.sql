
begin;

create table if not exists documents_part (
    like documents including all
) partition by range (published_at);

create table if not exists documents_y2025m09 partition of documents_part
  for values from ('2025-09-01') to ('2025-10-01');
create table if not exists documents_y2025m10 partition of documents_part
  for values from ('2025-10-01') to ('2025-11-01');

create or replace rule redirect_docs_insert as
on insert to documents do instead
  insert into documents_part values (new.*);

commit;
