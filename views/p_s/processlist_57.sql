/* Copyright (c) 2014, Oracle and/or its affiliates. All rights reserved.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA */

/*
 * View: processlist
 *
 * A detailed non-blocking processlist view to replace 
 * [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
 *
 * mysql> select * from processlist_full where conn_id is not null\G
 * ...
 * *************************** 8. row ***************************
 *                 thd_id: 31
 *                conn_id: 12
 *                   user: root@localhost
 *                     db: ps_helper
 *                command: Query
 *                  state: Sending data
 *                   time: 0
 *      current_statement: select * from processlist limit 5
 *           lock_latency: 684.00 us
 *          rows_examined: 0
 *              rows_sent: 0
 *          rows_affected: 0
 *             tmp_tables: 2
 *        tmp_disk_tables: 0
 *              full_scan: YES
 *         current_memory: 1.29 MiB
 *         last_statement: NULL
 * last_statement_latency: NULL
 *              last_wait: wait/synch/mutex/sql/THD::LOCK_query_plan
 *      last_wait_latency: 260.13 ns
 *                 source: sql_optimizer.cc:1075
 *
 * Versions: 5.7.2+
 *
 */
 
DROP VIEW IF EXISTS processlist;

CREATE SQL SECURITY INVOKER VIEW processlist AS
SELECT pps.thread_id AS thd_id,
       pps.processlist_id AS conn_id,
       IF(pps.name = 'thread/sql/one_connection', 
          CONCAT(pps.processlist_user, '@', pps.processlist_host), 
          REPLACE(pps.name, 'thread/', '')) user,
       pps.processlist_db AS db,
       pps.processlist_command AS command,
       pps.processlist_state AS state,
       pps.processlist_time AS time,
       sys.format_statement(pps.processlist_info) AS current_statement,
       sys.format_time(esc.lock_time) AS lock_latency,
       esc.rows_examined,
       esc.rows_sent,
       esc.rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables AS tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 
          'YES', 'NO') AS full_scan,
       sys.format_bytes(SUM(mem.current_number_of_bytes_used)) AS current_memory,
       IF(esc.timer_wait IS NOT NULL,
          sys.format_statement(esc.sql_text),
          NULL) AS last_statement,
       IF(esc.timer_wait IS NOT NULL,
          sys.format_time(esc.timer_wait),
          NULL) as last_statement_latency,
       ewc.event_name AS last_wait,
       IF(ewc.timer_wait IS NULL AND ewc.event_name IS NOT NULL, 
          'Still Waiting', 
          sys.format_time(ewc.timer_wait)) last_wait_latency,
       ewc.source
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current as esc USING (thread_id)
  LEFT JOIN performance_schema.memory_summary_by_thread_by_event_name as mem USING (thread_id)
GROUP BY thread_id
ORDER BY pps.processlist_time DESC, last_wait_latency DESC;

/*
 * View: processlist_raw
 *
 * A detailed non-blocking processlist view to replace 
 * [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
 * 
 * mysql> select * from processlist_full where conn_id is not null\G
 * *************************** 1. row ***************************
 *                 thd_id: 31
 *                conn_id: 12
 *                   user: root@localhost
 *                     db: ps_helper
 *                command: Query
 *                  state: Sending data
 *                   time: 0
 *      current_statement: select * from processlist_raw limit 5
 *           lock_latency: 1066000000
 *          rows_examined: 0
 *              rows_sent: 0
 *          rows_affected: 0
 *             tmp_tables: 2
 *        tmp_disk_tables: 1
 *              full_scan: YES
 *         current_memory: 1464694
 *         last_statement: NULL
 * last_statement_latency: NULL
 *              last_wait: wait/io/file/myisam/dfile
 *      last_wait_latency: 1602250
 *                 source: mf_iocache.c:163
 *
 * Versions: 5.7.2+
 *
 */
 
DROP VIEW IF EXISTS processlist_raw;

CREATE SQL SECURITY INVOKER VIEW processlist_raw AS
SELECT pps.thread_id AS thd_id,
       pps.processlist_id AS conn_id,
       IF(pps.name = 'thread/sql/one_connection', 
          CONCAT(pps.processlist_user, '@', pps.processlist_host), 
          REPLACE(pps.name, 'thread/', '')) user,
       pps.processlist_db AS db,
       pps.processlist_command AS command,
       pps.processlist_state AS state,
       pps.processlist_time AS time,
       pps.processlist_info AS current_statement,
       esc.lock_time AS lock_latency,
       esc.rows_examined,
       esc.rows_sent,
       esc.rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables AS tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 
          'YES', 'NO') AS full_scan,
       SUM(mem.current_number_of_bytes_used) AS current_memory,
       IF(esc.timer_wait IS NOT NULL,
          esc.sql_text,
          NULL) AS last_statement,
       IF(esc.timer_wait IS NOT NULL,
          esc.timer_wait,
          NULL) as last_statement_latency,
       ewc.event_name AS last_wait,
       IF(ewc.timer_wait IS NULL AND ewc.event_name IS NOT NULL, 
          'Still Waiting', 
          ewc.timer_wait) last_wait_latency,
       ewc.source
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current as esc USING (thread_id)
  LEFT JOIN performance_schema.memory_summary_by_thread_by_event_name as mem USING (thread_id)
GROUP BY thread_id
ORDER BY pps.processlist_time DESC, last_wait_latency DESC;