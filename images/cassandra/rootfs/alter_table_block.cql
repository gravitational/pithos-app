ALTER TABLE block WITH compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'sstable_size_in_mb', '512'};
