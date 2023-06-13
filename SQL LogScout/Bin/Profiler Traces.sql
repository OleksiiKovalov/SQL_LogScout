SET NOCOUNT ON;

print '--profiler trace summary--'
SELECT traceid, property, CONVERT (varchar(1024), value) AS value FROM :: fn_trace_getinfo(default)
go
print ''
print '--trace event details--'
      select trace_id,
            status,
            case when row_number = 1 then path else NULL end as path,
            case when row_number = 1 then max_size else NULL end as max_size,
            case when row_number = 1 then start_time else NULL end as start_time,
            case when row_number = 1 then stop_time else NULL end as stop_time,
            max_files, 
            is_rowset, 
            is_rollover,
            is_shutdown,
            is_default,
            buffer_count,
            buffer_size,
            last_event_time,
            event_count,
            trace_event_id, 
            trace_event_name, 
            trace_column_id,
            trace_column_name,
            expensive_event   
      from 
            (SELECT t.id AS trace_id, 
                  row_number() over (partition by t.id order by te.trace_event_id, tc.trace_column_id) as row_number, 
                  t.status, 
                  t.path, 
                  t.max_size, 
                  t.start_time,
                  t.stop_time, 
                  t.max_files, 
                  t.is_rowset, 
                  t.is_rollover,
                  t.is_shutdown,
                  t.is_default,
                  t.buffer_count,
                  t.buffer_size,
                  t.last_event_time,
                  t.event_count,
                  te.trace_event_id, 
                  te.name AS trace_event_name, 
                  tc.trace_column_id,
                  tc.name AS trace_column_name,
                  case when te.trace_event_id in (23, 24, 40, 41, 44, 45, 51, 52, 54, 68, 96, 97, 98, 113, 114, 122, 146, 180) then cast(1 as bit) else cast(0 as bit) end as expensive_event
            FROM sys.traces t 
                  CROSS apply ::fn_trace_geteventinfo(t .id) AS e 
                  JOIN sys.trace_events te ON te.trace_event_id = e.eventid 
                  JOIN sys.trace_columns tc ON e.columnid = trace_column_id) as x


go
print ''
print '--XEvent Session Details--'
SELECT convert(nvarchar(128), sess.NAME) as 'session_name', convert(nvarchar(128), event_name) as event_name,
CASE
 WHEN evt.event_name IN ( 'lock_released'
                         ,'lock_acquired'
                         ,'sql_statement_starting'
                         ,'sql_statement_completed'
                         ,'sp_statement_starting'
                         ,'sp_statement_completed'
                         ,'scan_started'
                         ,'scan_stopped'
                         ,'transaction_log'
                         ,'query_pre_execution_showplan'
                         ,'query_pre_execution_showplan'
                         ,'query_pre_execution_showplan'
                         ,'query_post_execution_showplan'
                         ,'query_pre_execution_showplan'
                         ,'query_post_execution_showplan'
                         ,'wait_info_external'
                         ,'wait_info'
                         ,'wait_completed'
                         ,'latch_released'
                         ,'latch_acquired'
                        )
 THEN Cast(1 AS BIT) ELSE Cast(0 AS BIT)
END AS expensive_event
FROM sys.dm_xe_sessions sess
 INNER JOIN sys.dm_xe_session_events evt
ON sess.address = evt.event_session_address 
print ''