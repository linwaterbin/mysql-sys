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
 *                 thd_id: 12400
 *                conn_id: 12379
 *                   user: root@localhost
 *                     db: ps_helper
 *                command: Query
 *                  state: Copying to tmp table
 *                   time: 0
 *      current_statement: select * from processlist_full where conn_id is not null
 *         last_statement: NULL
 * last_statement_latency: NULL
 *           lock_latency: 1.00 ms
 *          rows_examined: 0
 *              rows_sent: 0
 *          rows_affected: 0
 *             tmp_tables: 1
 *        tmp_disk_tables: 0
 *              full_scan: YES
 *              last_wait: wait/synch/mutex/sql/THD::LOCK_thd_data
 *      last_wait_latency: 62.53 ns
 *                 source: sql_class.h:3843
 *
 * Versions: 5.6.2+
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
       IF(esc.timer_wait IS NOT NULL,
          sys.format_statement(esc.sql_text),
          NULL) AS last_statement,
       IF(esc.timer_wait IS NOT NULL,
          sys.format_time(esc.timer_wait),
          NULL) as last_statement_latency,
       sys.format_time(esc.lock_time) AS lock_latency,
       esc.rows_examined,
       esc.rows_sent,
       esc.rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables as tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 
          'YES', 'NO') AS full_scan,
       ewc.event_name AS last_wait,
       IF(ewc.timer_wait IS NULL AND ewc.event_name IS NOT NULL, 
          'Still Waiting', 
          sys.format_time(ewc.timer_wait)) last_wait_latency,
       ewc.source
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current as esc USING (thread_id)
ORDER BY pps.processlist_time DESC, last_wait_latency DESC;

/*
 * View: processlist_raw
 *
 * A detailed non-blocking processlist view to replace 
 * [INFORMATION_SCHEMA. | SHOW FULL] PROCESSLIST
 * 
 * mysql> select * from processlist_full where conn_id is not null\G
 * *************************** 1. row ***************************
 *                 thd_id: 25
 *                conn_id: 6
 *                   user: root@localhost
 *                     db: ps_helper
 *                command: Query
 *                  state: Sending data
 *                   time: 0
 *      current_statement: select * from processlist_full where conn_id is not null
 *         last_statement: NULL
 * last_statement_latency: NULL
 *           lock_latency: 741.00 us
 *          rows_examined: 0
 *              rows_sent: 0
 *          rows_affected: 0
 *             tmp_tables: 1
 *        tmp_disk_tables: 0
 *              full_scan: YES
 *              last_wait: wait/synch/mutex/sql/THD::LOCK_query_plan
 *      last_wait_latency: 196.04 ns
 *                 source: sql_optimizer.cc:1075
 * 1 row in set (0.00 sec)
 *
 * Versions: 5.6.2+
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
       IF(esc.timer_wait IS NOT NULL,
          esc.sql_text,
          NULL) AS last_statement,
       IF(esc.timer_wait IS NOT NULL,
          esc.timer_wait,
          NULL) as last_statement_latency,
       esc.lock_time AS lock_latency,
       esc.rows_examined,
       esc.rows_sent,
       esc.rows_affected,
       esc.created_tmp_tables AS tmp_tables,
       esc.created_tmp_disk_tables as tmp_disk_tables,
       IF(esc.no_good_index_used > 0 OR esc.no_index_used > 0, 
          'YES', 'NO') AS full_scan,
       ewc.event_name AS last_wait,
       IF(ewc.timer_wait IS NULL AND ewc.event_name IS NOT NULL, 
          'Still Waiting', 
          ewc.timer_wait) last_wait_latency,
       ewc.source
  FROM performance_schema.threads AS pps
  LEFT JOIN performance_schema.events_waits_current AS ewc USING (thread_id)
  LEFT JOIN performance_schema.events_statements_current as esc USING (thread_id)
ORDER BY pps.processlist_time DESC, last_wait_latency DESC;