CREATE TABLE IF NOT EXISTS public.parquet_import_tracking (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR NOT NULL,
    file_name VARCHAR UNIQUE,
    file_type VARCHAR NOT NULL,
    is_empty BOOLEAN,
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_row_group_imported INT DEFAULT NULL,
    total_row_groups INT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_parquet_import_tracking_table_name ON public.parquet_import_tracking(table_name);
CREATE INDEX IF NOT EXISTS idx_parquet_import_tracking_imported_at ON public.parquet_import_tracking(imported_at);

CREATE TABLE IF NOT EXISTS public.casts
(
    id bigint PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "timestamp" timestamp without time zone NOT NULL,
    fid bigint NOT NULL,
    "hash" bytea NOT NULL,
    parent_hash bytea,
    parent_fid bigint,
    parent_url text COLLATE pg_catalog."default",
    "text" text COLLATE pg_catalog."default" NOT NULL,
    embeds jsonb NOT NULL DEFAULT '{}'::jsonb,
    mentions bigint[] NOT NULL DEFAULT '{}'::bigint[],
    mentions_positions smallint[] NOT NULL DEFAULT '{}'::smallint[],
    root_parent_hash bytea,
    root_parent_url text COLLATE pg_catalog."default",
    CONSTRAINT casts_hash_unique UNIQUE (hash)
);

CREATE TABLE IF NOT EXISTS public.fids
(
    fid bigint NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    custody_address bytea NOT NULL,
    registered_at timestamp with time zone,
    CONSTRAINT fids_pkey PRIMARY KEY (fid)
);

CREATE TABLE IF NOT EXISTS public.fnames
(
    fname text COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    custody_address bytea,
    expires_at timestamp without time zone,
    fid bigint,
    deleted_at timestamp without time zone,
    CONSTRAINT fnames_pkey PRIMARY KEY (fname)
);

CREATE TABLE IF NOT EXISTS public.links
(
    id bigint PRIMARY KEY,
    fid bigint,
    target_fid bigint,
    "hash" bytea NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "type" text COLLATE pg_catalog."default",
    display_timestamp timestamp without time zone,
    CONSTRAINT links_fid_target_fid_type_unique UNIQUE (fid, target_fid, type),
    CONSTRAINT links_hash_unique UNIQUE (hash)
);


CREATE TABLE IF NOT EXISTS public.reactions
(
    id bigint PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "timestamp" timestamp without time zone NOT NULL,
    reaction_type smallint NOT NULL,
    fid bigint NOT NULL,
    "hash" bytea NOT NULL,
    target_hash bytea,
    target_fid bigint,
    target_url text COLLATE pg_catalog."default",
    CONSTRAINT reactions_hash_unique UNIQUE (hash)
);

CREATE TABLE IF NOT EXISTS public.signers
(
    id bigint PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "timestamp" timestamp without time zone NOT NULL,
    fid bigint NOT NULL,
    "hash" bytea,
    custody_address bytea,
    signer bytea NOT NULL,
    "name" text COLLATE pg_catalog."default",
    app_fid bigint,
    CONSTRAINT unique_timestamp_fid_signer UNIQUE ("timestamp", fid, signer)
);

CREATE TABLE IF NOT EXISTS public.storage
(
    id bigint PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "timestamp" timestamp without time zone NOT NULL,
    fid bigint NOT NULL,
    units bigint NOT NULL,
    expiry timestamp without time zone NOT NULL,
    CONSTRAINT unique_fid_units_expiry UNIQUE (fid, units, expiry)
);

CREATE TABLE IF NOT EXISTS public.user_data
(
    id bigint PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "timestamp" timestamp without time zone NOT NULL,
    fid bigint NOT NULL,
    "hash" bytea NOT NULL UNIQUE,
    "type" smallint NOT NULL,
    "value" text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT user_data_fid_type_unique UNIQUE (fid, type)
);

CREATE TABLE IF NOT EXISTS public.verifications
(
    id bigint PRIMARY KEY,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp without time zone,
    "timestamp" timestamp without time zone NOT NULL,
    fid bigint NOT NULL,
    "hash" bytea NOT NULL UNIQUE,
    claim jsonb NOT NULL
);

CREATE TABLE IF NOT EXISTS public.warpcast_power_users
(
    fid bigint NOT NULL PRIMARY KEY,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);

CREATE TABLE IF NOT EXISTS public.profile_with_addresses
(
    fid bigint NOT NULL PRIMARY KEY,
    fname text COLLATE pg_catalog."default",
    display_name text COLLATE pg_catalog."default",
    avatar_url text COLLATE pg_catalog."default",
    bio text COLLATE pg_catalog."default",
    verified_addresses JSONB NOT NULL,
    updated_at timestamp without time zone NOT NULL
);

-- TODO: add indexes to the tables as needed
-- SHONI EDITS

-- Casts
CREATE INDEX IF NOT EXISTS idx_casts_hash ON public.casts (hash);
CREATE INDEX IF NOT EXISTS idx_casts_root_parent_deleted ON public.casts (root_parent_hash, deleted_at);
CREATE INDEX IF NOT EXISTS idx_casts_root_parent_hash ON public.casts (root_parent_hash);
CREATE INDEX IF NOT EXISTS idx_casts_hash_parent_hash ON public.casts (hash, parent_hash);
CREATE INDEX IF NOT EXISTS idx_casts_parent_hash ON public.casts (parent_hash);
CREATE INDEX IF NOT EXISTS idx_casts_fid ON public.casts (fid);
CREATE INDEX IF NOT EXISTS idx_casts_timestamp ON public.casts (timestamp);
CREATE INDEX IF NOT EXISTS idx_casts_parent_hash_hash ON public.casts (parent_hash, hash);
CREATE INDEX IF NOT EXISTS idx_casts_fid_timestamp_hash ON public.casts (fid, timestamp, hash);

-- Reactions
CREATE INDEX IF NOT EXISTS idx_reactions_target_type ON public.reactions (target_hash, reaction_type);
CREATE INDEX IF NOT EXISTS idx_reactions_target_fid_type ON public.reactions (target_hash, fid, reaction_type);
CREATE INDEX IF NOT EXISTS idx_reactions_target_hash ON public.reactions (target_hash);
CREATE INDEX IF NOT EXISTS idx_reactions_target_hash_reaction_type ON public.reactions (target_hash, reaction_type);

-- Warpcast Power Users
CREATE INDEX IF NOT EXISTS idx_warpcast_power_users_fid ON public.warpcast_power_users (fid);

-- Profile with Addresses
CREATE INDEX IF NOT EXISTS idx_profile_with_addresses_fid ON public.profile_with_addresses (fid);

-- Storage
CREATE UNIQUE INDEX IF NOT EXISTS unique_fid_units_expiry ON public.storage (fid, units, expiry);

-- User Data
CREATE UNIQUE INDEX IF NOT EXISTS user_data_hash_key ON public.user_data (hash);
CREATE UNIQUE INDEX IF NOT EXISTS user_data_fid_type_unique ON public.user_data (fid, type);

-- Links
CREATE UNIQUE INDEX IF NOT EXISTS links_fid_target_fid_type_unique ON public.links (fid, target_fid, type);
CREATE UNIQUE INDEX IF NOT EXISTS links_hash_unique ON public.links (hash);

-- Signers
CREATE UNIQUE INDEX IF NOT EXISTS unique_timestamp_fid_signer ON public.signers (timestamp, fid, signer);

-- Verifications
CREATE UNIQUE INDEX IF NOT EXISTS verifications_hash_key ON public.verifications (hash);

CREATE TABLE IF NOT EXISTS channels (
    id TEXT PRIMARY KEY,
    name TEXT,
    description TEXT,
    image_url TEXT,
    url TEXT,
    follower_count INTEGER
);

CREATE MATERIALIZED VIEW IF NOT EXISTS public.engagement_metrics
TABLESPACE pg_default
AS SELECT c.fid,
    c.hash,
    c."timestamp",
    c.deleted_at IS NOT NULL AS deleted,
    date_trunc('month'::text, c."timestamp") AS month,
    c.parent_url AS channel,
    COALESCE(likes.likes_count, 0::bigint) AS likes_count,
    COALESCE(recasts.recast_count, 0::bigint) AS recast_count,
    COALESCE(comments.comment_count, 0::bigint) AS comment_count
   FROM casts c
     LEFT JOIN LATERAL ( SELECT count(*) AS likes_count
           FROM reactions r
          WHERE r.target_hash = c.hash AND r.reaction_type = 1) likes ON true
     LEFT JOIN LATERAL ( SELECT count(*) AS recast_count
           FROM reactions r
          WHERE r.target_hash = c.hash AND r.reaction_type = 2) recasts ON true
     LEFT JOIN LATERAL ( SELECT count(*) AS comment_count
           FROM casts c2
          WHERE c2.parent_hash = c.hash) comments ON true
WITH DATA;


-- Engagement Metrics
CREATE INDEX IF NOT EXISTS idx_engagement_metrics_month ON public.engagement_metrics (month);
CREATE INDEX IF NOT EXISTS idx_engagement_metrics_fid ON public.engagement_metrics (fid);
CREATE UNIQUE INDEX IF NOT EXISTS idx_engagement_metrics_unique ON public.engagement_metrics (fid, hash);


