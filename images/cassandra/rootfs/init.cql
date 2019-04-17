CREATE KEYSPACE IF NOT EXISTS storage WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 'REPLICATION_FACTOR'}  AND durable_writes = true;

CREATE TABLE IF NOT EXISTS storage.inode_blocks (
    inode uuid,
    version timeuuid,
    block bigint,
    PRIMARY KEY ((inode, version), block)
) WITH CLUSTERING ORDER BY (block ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 300000
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';

CREATE TABLE IF NOT EXISTS storage.object (
    bucket text,
    object text,
    acl text,
    atime text,
    checksum text,
    inode uuid,
    metadata map<text, text>,
    size bigint,
    storageclass text,
    version timeuuid,
    PRIMARY KEY (bucket, object)
) WITH CLUSTERING ORDER BY (object ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 300000
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
CREATE INDEX IF NOT EXISTS object_inode ON storage.object (inode);

CREATE TABLE IF NOT EXISTS storage.bucket (
    bucket text PRIMARY KEY,
    acl text,
    cors text,
    created text,
    policy text,
    region text,
    tenant text,
    versioned boolean,
    website text
) WITH bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 300000
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
CREATE INDEX IF NOT EXISTS bucket_tenant ON storage.bucket (tenant);

CREATE TABLE IF NOT EXISTS storage.upload (
    bucket text,
    object text,
    upload uuid,
    partno int,
    checksum text,
    inode uuid,
    modified text,
    size bigint,
    version uuid,
    PRIMARY KEY ((bucket, object, upload), partno)
) WITH CLUSTERING ORDER BY (partno ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 300000
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';

CREATE TABLE IF NOT EXISTS storage.object_uploads (
    bucket text,
    object text,
    upload uuid,
    metadata map<text, text>,
    PRIMARY KEY ((bucket, object), upload)
) WITH CLUSTERING ORDER BY (upload ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 300000
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
CREATE INDEX IF NOT EXISTS upload_bucket ON storage.object_uploads (bucket);

CREATE TABLE IF NOT EXISTS storage.block (
    inode uuid,
    version timeuuid,
    block bigint,
    offset bigint,
    chunksize int,
    payload blob,
    PRIMARY KEY ((inode, version, block), offset)
) WITH CLUSTERING ORDER BY (offset ASC)
    AND bloom_filter_fp_chance = 0.01
    AND caching = {'keys': 'ALL', 'rows_per_partition': 'NONE'}
    AND comment = ''
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.LeveledCompactionStrategy', 'sstable_size_in_mb': '512'}
    AND compression = {'chunk_length_in_kb': '64', 'class': 'org.apache.cassandra.io.compress.LZ4Compressor'}
    AND crc_check_chance = 1.0
    AND default_time_to_live = 0
    AND gc_grace_seconds = 864000
    AND max_index_interval = 2048
    AND memtable_flush_period_in_ms = 300000
    AND min_index_interval = 128
    AND read_repair_chance = 0.0
    AND speculative_retry = '99PERCENTILE';
