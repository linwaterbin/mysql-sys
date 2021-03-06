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
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA */

DROP PROCEDURE IF EXISTS ps_setup_disable_background_threads;

DELIMITER $$

CREATE DEFINER='root'@'localhost' PROCEDURE ps_setup_disable_background_threads ()
    COMMENT '
             Description
             -----------

             Disable all background thread instrumentation within Performance Schema.

             Requires the SUPER privilege for "SET sql_log_bin = 0;".

             Parameters
             -----------

             None.

             Example
             -----------

             mysql> CALL sys.ps_setup_disable_background_threads();
             +--------------------------------+
             | summary                        |
             +--------------------------------+
             | Disabled 18 background threads |
             +--------------------------------+
             1 row in set (0.00 sec)
            '
    SQL SECURITY INVOKER
    NOT DETERMINISTIC
    MODIFIES SQL DATA
BEGIN
    SET @log_bin := @@sql_log_bin;
    SET sql_log_bin = 0;

    UPDATE performance_schema.threads
       SET instrumented = 'NO'
     WHERE type = 'BACKGROUND';

    SELECT CONCAT('Disabled ', @rows := ROW_COUNT(), ' background thread', IF(@rows != 1, 's', '')) AS summary;

    SET sql_log_bin = @log_bin; 
END$$

DELIMITER ;
