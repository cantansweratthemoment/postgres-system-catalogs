DO
$$
    declare
        schemaName text = 's285550';
        columnName text = 'id';
        result     text = '';
        counter    int  = 0;
        i          int  = 0;
        columnInfo cursor for (
            SELECT pg_class.relname,
                   pt.typname,
                   col_description(pg_class.oid, pa.attnum) as comment,
                   (select string_agg(distinct pg_indexes.indexname, ',')
                    from information_schema.columns,
                         pg_indexes
                    where column_name = pa.attname
                      and pg_indexes.tablename = pg_class.relname
                      and pg_indexes.indexdef ~* (pa.attname)
                   )                                        as index,
                   (select string_agg(distinct pc.conname, ',')
                    from pg_class as constraints_pg_class
                             join pg_attribute constraints_pa on constraints_pg_class.oid = constraints_pa.attrelid
                             left join pg_constraint pc on constraints_pa.attrelid = pc.conrelid
                    where constraints_pa.attname = pa.attname
                      and constraints_pg_class.relname = pg_class.relname
                      and pc.conname ~* (pa.attname)
                   )                                        as constr
            from pg_class
                     join pg_namespace pn on pg_class.relnamespace = pn.oid
                     join pg_attribute pa on pg_class.oid = pa.attrelid
                     join pg_type pt on pa.atttypid = pt.oid
            where pa.attname = columnName
              and pn.nspname = schemaName
              and pg_class.reltype != 0
        );
    begin
        select count(*)
        into counter
        from pg_class
                 join pg_namespace pn on pg_class.relnamespace = pn.oid
                 join pg_attribute pa on pg_class.oid = pa.attrelid
        where pa.attname = columnName
          and pn.nspname = schemaName
          and pg_class.reltype != 0;

        if counter < 0 then
            raise exception 'Data not found!';
        else
            select format('%-5s %-20s %-25s %-15s', 'No', 'Имя столбца', 'Имя таблицы', 'Атрибуты') into result;
            raise info '%', result;
            select format('%-5s %-20s %-25s %-15s', '--', '-----------', '-----------', '--------') into result;
            raise info '%', result;
            for currentColumn in columnInfo
                loop
                    select format('%-5s %-20s %-25s %-15s %s', i + 1, columnName, currentColumn.relname, 'Type',
                                  currentColumn.typname)
                    into result;
                    raise info '%', result;
                    if currentColumn.constr IS NOT NULL then
                        select format('%-5s %-20s %-25s %-15s %s', '.', ' ', ' ', 'Constr', currentColumn.constr)
                        into result;
                        raise info '%', result;
                    end if;
                    if currentColumn.comment IS NOT NULL then
                        select format('%-5s %-20s %-25s %-15s %s', '.', ' ', ' ', 'Comment', currentColumn.comment)
                        into result;
                        raise info '%', result;
                    end if;
                    if currentColumn.index IS NOT NULL then
                        select format('%-5s %-20s %-25s %-15s', '.', ' ', ' ', 'Index', currentColumn.index)
                        into result;
                        raise info '%', result;
                    end if;
                    i := i + 1;
                end loop;
        end if;
    end
$$ LANGUAGE plpgsql;