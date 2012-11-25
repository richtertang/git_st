--察看系统总容量
--可以通过使用 sp_spaceused 系统存储过程来估计完整备份的大小。

USE AdventureWorks;
GO
EXEC sp_spaceused ;
GO

--查询每张表数据条数
declare   @tbName     nvarchar(500)
declare   @ct      int   
declare   @csql   nvarchar(500)   
declare   #tb   cursor   for  SELECT OBJECT_NAME (id) As TableName FROM sysobjects WHERE xtype = 'U' AND OBJECTPROPERTY (id, 'IsMSShipped') = 0 order by 1
open   #tb 
 fetch   next   from   #tb   into   @tbName
 while   @@fetch_status=0 
 begin  
  set @csql = N'Select @ct= Count(*)  From ' + @tbName
  Exec dbo.sp_executesql  @csql,N'@ct   int   output',@ct   output 
  Print @tbName + '---' + Cast(@ct  As  nvarchar(500))
 fetch   next   from   #tb   into   @tbName
 end     
close   #tb 
deallocate   #tb 

--类似oracle desc
sp_help   talbename

SELECT @@MAX_CONNECTIONS 
sp_lock
sp_who

--当前schema的表
select count(*) from sys.tables

--获得表名扩展信息
SELECT objtype, objname, name, value FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', default, NULL, NULL) order by 2;

--获得表列名信息
SELECT  objname,  value FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', 'F_PORTYARD_ATTR_HEAD', 'column', default);


select 'delete from ' + s.name+' ;'+' /* '+CONVERT( varchar(20),c.value) +' */'  from sys.tables s , ( SELECT  objname name ,  value FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', default, NULL, NULL)) c where s.name=c.name COLLATE Latin1_General_CI_AI

--自动组装delete语句
with cc as (select 'delete from ' + s.name+' ;' d ,' /* '+CONVERT( varchar(20),c.value) +' */' c from sys.tables s , ( SELECT  objname name ,  value FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', default, NULL, NULL)) c where s.name=c.name COLLATE Latin1_General_CI_AI),
o as (select 'delete from ' + name +' ;' d ,''c  from sys.tables)
select o.d,cc.c from cc  right join o on( cc.d=o.d) order by 

--以 XML 格式返回计划句柄指定的批查询的显示计划。计划句柄指定的计划可以处于缓存或正在执行状态。http://msdn.microsoft.com/zh-cn/library/ms189747%28v=SQL.90%29.aspx
sys.dm_exec_query_plan

SET SHOWPLAN_ALL  on;
SET SHOWPLAN_ALL  off;
SET SHOWPLAN_TEXT on;
SET SHOWPLAN_TEXT off;
SET STATISTICS TIME  on;
SET STATISTICS xml on;
SET STATISTICS xml off;
SET STATISTICS IO on;
SET STATISTICS IO off;
set statistics profile on;
set statistics profile off;

--如何查询index目前的状态？
sys.dm_db_index_physical_stats 动态管理函数将替换 DBCC SHOWCONTIG 语

DECLARE @db_id INT;
SET @db_id = DB_ID(N'DLHGWLJK');
begin
  select * from sys.dm_db_index_physical_stats(@db_id,null,NULL,null,null)
end 

select o.name ,i.* from sys.dm_db_index_physical_stats  (DB_ID(N'DLHGWLJK'),null,NULL,null,null) i , sys.objects o  where    fragment_count >0  and i.object_id = o.object_id 

select * from sys.dm_db_index_operational_stats (DB_ID(N'DLHGWLJK'),null,NULL,null) where row_lock_count >10

--如何查询index目前的状态？ 
sys.indexes 


--察看tempdb大小
select a.filename,a.name,a.size*8.0/1024.0 as originalsize_MB,
f.size*8.0/1024.0 as currentsize_MB
from master..sysaltfiles a join tempdb..sysfiles f on a.fileid=f.fileid
where dbid=db_id('tempdb')
and a.size<>f.size
--调整tempdb
USE master
GO
ALTER DATABASE tempdb
MODIFY FILE (NAME = tempdev,SIZE = 100MB)

--察看索引状况
DECLARE @db_id SMALLINT;
SET @db_id = DB_ID(N'DLHGWLJK2');
IF @db_id IS NULL
BEGIN;
    PRINT N'Invalid database';
END;
ELSE
BEGIN;
    SELECT 
o.name,
s.* FROM sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL , 'SAMPLED ') s 
join sys.objects o on (s.object_id=o.object_id);
END;
GO

exec sp_addlinkedserver 'server_v ', ' ', 'SQLOLEDB ', 'SERVER1\SQLSERVER_v '
exec sp_dropserver 'server_v ', 'droplogins '
exec sp_addlinkedsrvlogin 'server_v ', 'false ',null, 'sa ', 'root '


SELECT COUNT(*) * 8 AS cached_pages_kb,
       CONVERT(VARCHAR(5),
               CONVERT(DECIMAL(5, 2),
                       (100 -
                       1.0 * (SELECT COUNT(*)
                                 FROM SYS.dm_os_buffer_descriptors b
                                WHERE b.database_id = a.database_id
                                  AND is_modified = 0) / COUNT(*) * 100.0))) + '%' modified_percentage,
       CASE database_id
         WHEN 32767 THEN
          'ResourceDb'
         ELSE
          db_name(database_id)
       END AS database_name
  FROM SYS.dm_os_buffer_descriptors a
 GROUP BY db_name(database_id), database_id
 ORDER BY cached_pages_kb DESC;

SELECT count(*) * 8 AS cached_pages_kb,
       obj.name,
       obj.index_id,
       b.type_desc,
       b.name
  FROM sys.dm_os_buffer_descriptors AS bd
 INNER JOIN (SELECT object_name(object_id) AS name,
                    index_id,
                    allocation_unit_id,
                    object_id
               FROM sys.allocation_units AS au
              INNER JOIN sys.partitions AS p ON au.container_id = p.hobt_id
                                            AND (au.type = 1 OR au.type = 3)
             UNION ALL
             SELECT object_name(object_id) AS name,
                    index_id,
                    allocation_unit_id,
                    object_id
               FROM sys.allocation_units AS au
              INNER JOIN sys.partitions AS p ON au.container_id =
                                                p.partition_id
                                            AND au.type = 2) AS obj ON bd.allocation_unit_id =
                                                                       obj.allocation_unit_id
  LEFT JOIN sys.indexes b on b.object_id = obj.object_id
                         AND b.index_id = obj.index_id
 WHERE database_id = db_id()
 GROUP BY obj.name, obj.index_id, b.name, b.type_desc
 ORDER BY cached_pages_kb DESC;


--察看锁
SELECT request_session_id,
       resource_type,
       resource_associated_entity_id,
       request_status,
       request_mode,
       resource_description,
       p.object_id,
       object_name(p.object_id) as object_name,
       p.*
  FROM sys.dm_tran_locks
  left join sys.partitions p on sys.dm_tran_locks.resource_associated_entity_id =
                                p.hobt_id
 WHERE resource_database_id = db_id('XMHCBSG')
 order by request_session_id, resource_type, resource_associated_entity_id

exec   sp_helpconstraint   'MESSAGE_DEAL' --察看表的约束

 运行 
dbcc  freeProcCache -- 清除缓存

CHECKPOINT 
DBCC DROPCLEANBUFFERS  --清空buffer


-------------
SELECT DB_ID(DB.dbid) '数据库名',
       OBJECT_ID(db.objectid) '对象',
       QS.creation_time '编译计划的时间',
       QS.last_execution_time '上次执行计划的时间',
       QS.execution_count '执行的次数',
       QS.total_elapsed_time / 1000 '占用的总时间（秒）',
       QS.total_physical_reads '物理读取总次数',
       QS.total_worker_time / 1000 'CPU 时间总量（秒）',
       QS.total_logical_writes '逻辑写入总次数',
       QS.total_logical_reads N'逻辑读取总次数',
       QS.total_elapsed_time / 1000 N'总花费时间（秒）',
       SUBSTRING(ST.text,
                 (QS.statement_start_offset / 2) + 1,
                 ((CASE statement_end_offset
                   WHEN -1 THEN
                    DATALENGTH(st.text)
                   ELSE
                    QS.statement_end_offset
                 END - QS.statement_start_offset) / 2) + 1) AS '执行语句'
  FROM sys.dm_exec_query_stats AS QS
 CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
 INNER JOIN (SELECT *
               FROM sys.dm_exec_cached_plans cp
              CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle)) DB ON QS.plan_handle =
                                                                        DB.plan_handle
 where SUBSTRING(st.text,
                 (qs.statement_start_offset / 2) + 1,
                 ((CASE statement_end_offset WHEN - 1 THEN
                  DATALENGTH(st.text) ELSE qs.statement_end_offset
                  END - qs.statement_start_offset) / 2) + 1) not like
       '%fetch%'
 ORDER BY QS.total_elapsed_time / 1000 DESC
---------------------------------------


select top 1000 *  into H_ENTRY_HEAD from DLHGWLJK.dbo.H_ENTRY_HEAD

--获得表/列信息
SELECT  c.name, a.name,a.xtype ,a.length,ss.name FROM sysobjects c join syscolumns a on (a.id=c.id  and c.xtype='U' )  join sys.types ss 
on (a.xtype=ss.system_type_id)order by 1,2

select 'drop table ' + s.name+' ;' from sys.tables s 

察看当前的所有trace
select * from  fn_trace_getinfo(1) 

缓冲池内数据库缓冲池中各个数据库的分布情况
select case database_id
         when 32767 then
          'resourcedb'
         else
          db_name(database_id)
       end as database_name,
       count(*) as cached_pages_count
  from sys.dm_os_buffer_descriptors
 group by db_name(database_id), database_id
 order by cached_pages_count desc;

--缓冲池中前十位消耗内存最大的内存组件
select top 10 type, sum(single_pages_kb) as spa mem, kb
  from sys.dm_os_memory_clerks
 group by type
 order by sum(single_pages_kb) desc

提供有关 CPU 时间、IO 读写以及按平均 CPU 时间排在前15个查询的执行次数的信息
SELECT TOP 15 total_worker_time/execution_count AS [Avg CPU Time],
(SELECT SUBSTRING(text,
                 statement_start_offset / 2,
                 (CASE
                   WHEN statement_end_offset = -1 then
                    LEN(CONVERT(nvarchar(max), text)) * 2
                   ELSE
                    statement_end_offset
                 end - statement_start_offset) / 2)
  FROM sys.dm_exec_sql_text(sql_handle)) AS query_text 
FROM sys.dm_exec_query_stats ORDER BY [Avg CPU Time] DESC

SELECT TOP 25 max_elapsed_time
 AS [elapsed CPU Time],(select text from sys.dm_exec_sql_text(sql_handle)) alltext,
(SELECT SUBSTRING(text,
                 statement_start_offset / 2+1,
                 (CASE
                   WHEN statement_end_offset = -1 then
                    LEN(CONVERT(nvarchar(max), text)) * 2
                   ELSE
                    statement_end_offset
                 end - statement_start_offset) / 2)
  FROM sys.dm_exec_sql_text(sql_handle)) AS query_text 
FROM sys.dm_exec_query_stats ORDER BY [elapsed CPU Time] DESC

--缓冲对象类型排行
  select objtype 'cached object type',
         count(*) 'number of plans',
         sum(cast(size_in_bytes as bigint)) / 1024 / 1024 'plan cache size(MB)',
         avg(usecounts) 'avg use count'
    from sys.dm_exec_cached_plans
   group by objtype
   order by 3 desc

查询缓存的执行计划
 SELECT top 20 (select query_plan from sys.dm_exec_query_plan(plan_handle)),
        usecounts,
        refcounts,
        objtype,
        cacheobjtype,
        size_in_bytes
   FROM sys.dm_exec_cached_plans
  order by 6 desc

察看connect
exec sp_who
exec sp_who2

--察看用户对象的段大小
select o.name,s.*  from sys.dm_db_partition_stats  s , sys.objects o where  s.object_id=o.object_id and  s.object_id IN (select object_id from sys.objects where type='U')


SET SHOWPLAN_XML ON 
此语句导致 SQL Server 不执行 Transact-SQL 语句。而 Microsoft SQL Server 返回有关如何在正确的 XML 文档中执行语句的执行计划信息。有关详细信息，请参阅 SET SHOWPLAN_XML (Transact-SQL)。
SET SHOWPLAN_TEXT ON 
执行该 SET 语句后，SQL Server 以文本格式返回每个查询的执行计划信息。不执行 Transact-SQL 语句或批处理。有关详细信息，请参阅 SET SHOWPLAN_TEXT (Transact-SQL)。
SET SHOWPLAN_ALL ON 
该语句与 SET SHOWPLAN_TEXT 相似，但比 SHOWPLAN_TEXT 的输出格式更详细。有关详细信息，请参阅 SET SHOWPLAN_ALL (Transact-SQL)。 
SET STATISTICS XML ON 
该语句执行后，除了返回常规结果集外，还返回每个语句的执行信息。输出是正确的 XML 文档集。SET STATISTICS XML ON 为执行的每个语句生成一个 XML 输出文档。SET SHOWPLAN_XML ON 和 SET STATISTICS XML ON 的不同之处在于第二个 SET 选项执行 Transact-SQL 语句或批处理。SET STATISTICS XML ON 输出还包含有关各种操作符处理的实际行数和操作符的实际执行数。有关详细信息，请参阅 SET STATISTICS XML (Transact-SQL)。
SET STATISTICS PROFILE ON 
该语句执行后，除了返回常规结果集外，还返回每个语句的执行信息。两个 SET 语句选项都提供文本格式的输出。SET SHOWPLAN_XML ON 和 SET STATISTICS PROFILE ON 的不同之处在于第二个 SET 选项执行 Transact-SQL 语句或批处理。SET STATISTICS PROFILE ON 输出还包含有关各种操作符处理的实际行数和操作符的实际执行数。有关详细信息，请参阅 SET STATISTICS PROFILE (Transact-SQL)。 
SET STATISTICS IO ON 
显示 Transact-SQL 语句执行后生成的有关磁盘活动数量的信息。此 SET 选项生成文本输出。有关详细信息，请参阅 SET STATISTICS IO (Transact-SQL)。 
SET STATISTICS TIME ON 
执行语句后，显示分析、编译和执行每个 Transact-SQL 语句所需的毫秒数。此 SET 选项生成文本输出。有关详细信息，请参阅 SET STATISTICS TIME (Transact-SQL)。


SET STATISTICS PROFILE ON 
SET STATISTICS IO ON 
SET STATISTICS TIME ON 

--改变大小写
alter database test COLLATE Chinese_PRC_CI_AS
