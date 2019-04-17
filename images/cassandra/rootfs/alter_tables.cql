ALTER TABLE block WITH compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'sstable_size_in_mb': '512'} AND memtable_flush_period_in_ms = 300000;
ALTER TABLE inode_blocks WITH memtable_flush_period_in_ms = 300000;
ALTER TABLE object WITH memtable_flush_period_in_ms = 300000;
ALTER TABLE bucket WITH memtable_flush_period_in_ms = 300000;
ALTER TABLE upload WITH memtable_flush_period_in_ms = 300000;
ALTER TABLE object_uploads WITH memtable_flush_period_in_ms = 300000;
