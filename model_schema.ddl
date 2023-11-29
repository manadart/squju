CREATE TABLE change_log_edit_type (
    id        INT PRIMARY KEY,
    edit_type TEXT
);

CREATE UNIQUE INDEX idx_change_log_edit_type_edit_type
ON change_log_edit_type (edit_type);

-- The change log type values are bitmasks, so that multiple types can be
-- expressed when looking for changes.
INSERT INTO change_log_edit_type VALUES
    (1, 'create'),
    (2, 'update'),
    (4, 'delete');

CREATE TABLE change_log_namespace (
    id          INT PRIMARY KEY,
    namespace   TEXT,
    description TEXT
);

CREATE UNIQUE INDEX idx_change_log_namespace_namespace
ON change_log_namespace (namespace);

CREATE TABLE change_log (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    edit_type_id        INT NOT NULL,
    namespace_id        INT NOT NULL,
    changed             TEXT NOT NULL,
    created_at          DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'utc')),
    CONSTRAINT          fk_change_log_edit_type
            FOREIGN KEY (edit_type_id)
            REFERENCES  change_log_edit_type(id),
    CONSTRAINT          fk_change_log_namespace
            FOREIGN KEY (namespace_id)
            REFERENCES  change_log_namespace(id)
);

-- The change log witness table is used to track which nodes have seen
-- which change log entries. This is used to determine when a change log entry
-- can be deleted.
-- We'll delete all change log entries that are older than the lower_bound
-- change log entry that has been seen by all controllers.
CREATE TABLE change_log_witness (
    controller_id       TEXT PRIMARY KEY,
    lower_bound         INT NOT NULL DEFAULT(-1),
    upper_bound         INT NOT NULL DEFAULT(-1),
    updated_at          DATETIME NOT NULL DEFAULT(STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW', 'utc'))
);

CREATE TABLE life (
    id    INT PRIMARY KEY,
    value TEXT NOT NULL
);

INSERT INTO life VALUES
    (0, 'alive'),
    (1, 'dying'),
    (2, 'dead');

INSERT INTO change_log_namespace VALUES
    (1, 'model_config', 'model config changes based on config key'),
    (2, 'object_store_metadata_path', 'object store metadata path changes based on the path')

CREATE TABLE model_config (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE space (
    uuid            TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    is_public       BOOLEAN
);

CREATE UNIQUE INDEX idx_spaces_uuid_name
ON space (name);

CREATE TABLE provider_space (
    provider_id     TEXT PRIMARY KEY,
    space_uuid      TEXT NOT NULL,
    CONSTRAINT      fk_provider_space_space_uuid
        FOREIGN KEY     (space_uuid)
        REFERENCES      space(uuid)
);

CREATE UNIQUE INDEX idx_provider_space_space_uuid
ON provider_space (space_uuid);

CREATE TABLE subnet (
    uuid                         TEXT PRIMARY KEY,
    cidr                         TEXT NOT NULL,
    vlan_tag                     INT,
    is_public                    BOOLEAN,
    space_uuid                   TEXT,
    subnet_type_uuid             TEXT,
    CONSTRAINT                   fk_subnets_spaces
        FOREIGN KEY                  (space_uuid)
        REFERENCES                   space(uuid),
    CONSTRAINT                   fk_subnet_types
        FOREIGN KEY                  (subnet_type_uuid)
        REFERENCES                   subnet_type(uuid)
);

CREATE TABLE subnet_type (
    uuid                         TEXT PRIMARY KEY,
    name                         TEXT NOT NULL,
    is_usable                    BOOLEAN,
    is_space_settable            BOOLEAN
);

INSERT INTO subnet_type VALUES
    (0, 'base', true, true),    -- The base (or standard) subnet type. If another subnet is an overlay of a base subnet in fan bridging, then the base subnet is the underlay in fan terminology.
    (1, 'fan_overlay', false, false),
    (2, 'fan_overlay_segment', true, true);

CREATE TABLE subnet_association_type (
    uuid                         TEXT PRIMARY KEY,
    name                         TEXT NOT NULL
);

INSERT INTO subnet_association_type VALUES
    (0, 'overlay_of');    -- The subnet is an overlay of other (an underlay) subnet.

CREATE TABLE subnet_type_association_type (
    subject_subnet_type_uuid       TEXT PRIMARY KEY,
    associated_subnet_type_uuid    TEXT NOT NULL,
    association_type_uuid          TEXT NOT NULL,
    CONSTRAINT                     fk_subject_subnet_type_uuid
        FOREIGN KEY                    (subject_subnet_type_uuid)
        REFERENCES                     subnet_type(uuid),
    CONSTRAINT                     fk_associated_subnet_type_uuid
        FOREIGN KEY                    (associated_subnet_type_uuid)
        REFERENCES                     subnet_association_type(uuid),
    CONSTRAINT                     fk_association_type_uuid
        FOREIGN KEY                    (association_type_uuid)
        REFERENCES                     subnet_association_type(uuid)
);

INSERT INTO subnet_type_association_type VALUES
    (1, 0, 0);    -- This reference "allowable" association means that a 'fan_overlay' subnet can only be an overlay of a 'base' subnet.

CREATE TABLE subnet_association (
    subject_subnet_uuid            TEXT PRIMARY KEY,
    associated_subnet_uuid         TEXT NOT NULL,
    association_type_uuid          TEXT NOT NULL,
    CONSTRAINT                     fk_subject_subnet_uuid
        FOREIGN KEY                    (subject_subnet_uuid)
        REFERENCES                     subnet(uuid),
    CONSTRAINT                     fk_associated_subnet_uuid
        FOREIGN KEY                    (associated_subnet_uuid)
        REFERENCES                     subnet(uuid),
    CONSTRAINT                     fk_association_type_uuid
        FOREIGN KEY                    (association_type_uuid)
        REFERENCES                     subnet_association_type(uuid)
);

CREATE UNIQUE INDEX idx_subnet_association
ON subnet_association (subject_subnet_uuid, associated_subnet_uuid);

CREATE TABLE provider_subnet (
    provider_id     TEXT PRIMARY KEY,
    subnet_uuid     TEXT NOT NULL,
    CONSTRAINT      fk_provider_subnet_subnet_uuid
        FOREIGN KEY     (subnet_uuid)
        REFERENCES      subnet(uuid)
);

CREATE UNIQUE INDEX idx_provider_subnet_subnet_uuid
ON provider_subnet (subnet_uuid);

CREATE TABLE provider_network (
    uuid                TEXT PRIMARY KEY,
    provider_network_id TEXT
);

CREATE TABLE provider_network_subnet (
    provider_network_uuid TEXT PRIMARY KEY,
    subnet_uuid           TEXT NOT NULL,
    CONSTRAINT            fk_provider_network_subnet_provider_network_uuid
        FOREIGN KEY           (provider_network_uuid)
        REFERENCES            provider_network(uuid),
    CONSTRAINT            fk_provider_network_subnet_uuid
        FOREIGN KEY           (subnet_uuid)
        REFERENCES            subnet(uuid)
);

CREATE UNIQUE INDEX idx_provider_network_subnet_uuid
ON provider_network_subnet (subnet_uuid);

CREATE TABLE availability_zone (
    uuid            TEXT PRIMARY KEY,
    name            TEXT
);

CREATE TABLE availability_zone_subnet (
    uuid                   TEXT PRIMARY KEY,
    availability_zone_uuid TEXT NOT NULL,
    subnet_uuid            TEXT NOT NULL,
    CONSTRAINT             fk_availability_zone_availability_zone_uuid
        FOREIGN KEY            (availability_zone_uuid)
        REFERENCES             availability_zone(uuid),
    CONSTRAINT             fk_availability_zone_subnet_uuid
        FOREIGN KEY            (subnet_uuid)
        REFERENCES             subnet(uuid)
);

CREATE INDEX idx_availability_zone_subnet_availability_zone_uuid
ON availability_zone_subnet (uuid);

CREATE INDEX idx_availability_zone_subnet_subnet_uuid
ON availability_zone_subnet (subnet_uuid);

CREATE TABLE application (
    uuid TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE UNIQUE INDEX idx_application_name
ON application (name);

CREATE TABLE net_node (
    uuid TEXT PRIMARY KEY
);

CREATE TABLE machine (
    uuid            TEXT PRIMARY KEY,
    machine_id      TEXT NOT NULL,
    net_node_uuid   TEXT NOT NULL,
    CONSTRAINT      fk_machine_net_node
        FOREIGN KEY (net_node_uuid)
        REFERENCES  net_node(uuid)
);

CREATE UNIQUE INDEX idx_machine_id
ON machine (machine_id);

CREATE UNIQUE INDEX idx_machine_net_node
ON machine (net_node_uuid);

CREATE TABLE cloud_service (
    uuid             TEXT PRIMARY KEY,
    net_node_uuid    TEXT NOT NULL,
    application_uuid TEXT NOT NULL,
    CONSTRAINT       fk_cloud_service_net_node
        FOREIGN KEY  (net_node_uuid)
        REFERENCES   net_node(uuid),
    CONSTRAINT       fk_cloud_application
        FOREIGN KEY  (application_uuid)
        REFERENCES   application(uuid)
);

CREATE UNIQUE INDEX idx_cloud_service_net_node
ON cloud_service (net_node_uuid);

CREATE UNIQUE INDEX idx_cloud_service_application
ON cloud_service (application_uuid);

CREATE TABLE cloud_container (
    uuid            TEXT PRIMARY KEY,
    net_node_uuid   TEXT NOT NULL,
    CONSTRAINT      fk_cloud_container_net_node
        FOREIGN KEY (net_node_uuid)
        REFERENCES  net_node(uuid)
);

CREATE UNIQUE INDEX idx_cloud_container_net_node
ON cloud_container (net_node_uuid);

CREATE TABLE unit (
    uuid             TEXT PRIMARY KEY,
    unit_id          TEXT NOT NULL,
    application_uuid TEXT NOT NULL,
    net_node_uuid    TEXT NOT NULL,
    CONSTRAINT       fk_unit_application
        FOREIGN KEY  (application_uuid)
        REFERENCES   application(uuid),
    CONSTRAINT       fk_unit_net_node
        FOREIGN KEY  (net_node_uuid)
        REFERENCES   net_node(uuid)
);

CREATE UNIQUE INDEX idx_unit_id
ON unit (unit_id);

CREATE INDEX idx_unit_application
ON unit (application_uuid);

CREATE UNIQUE INDEX idx_unit_net_node
ON unit (net_node_uuid);

CREATE TABLE storage_pool (
    uuid TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    -- TODO (manadart 2023-11-29): Storage pools in Mongo were stored as settings.
    -- The types are sourced from the provider.
    -- We can:
    --   1. Leave it as text on the basis that we don't know up front what types the provider offers.
    --   2. Make a lookup with all the known types, which would need maintenance over the long run.
    --   3. Populate a lookup at model creation with the provider's known types.
    -- Option 1 preserves the status quo.
    type TEXT NOT NULL
);

CREATE TABLE storage_pool_attributes (
    storage_pool_uuid TEXT NOT NULL,
    key               TEXT,
    value             TEXT,
    CONSTRAINT       fk_storage_pool_attribute_pool
        FOREIGN KEY  (storage_pool_uuid)
        REFERENCES   storage_pool(uuid)
);

CREATE UNIQUE INDEX idx_storage_pool_attribute
ON storage_pool_attributes (storage_pool_uuid, key);

CREATE TABLE storage_type (
    id   INT PRIMARY KEY,
    type TEXT
);

CREATE UNIQUE INDEX idx_storage_type_type
ON storage_type (type);

INSERT INTO storage_type VALUES
    (0, 'block'),
    (1, 'filesystem');

CREATE TABLE storage_instance (
    uuid            TEXT PRIMARY KEY,
    storage_type_id INT NOT NULL,
    name            TEXT NOT NULL,
    life_id         INT NOT NULL,
    CONSTRAINT       fk_storage_instance_type
        FOREIGN KEY  (storage_type_id)
        REFERENCES   storage_type(id),
    CONSTRAINT       fk_storage_instance_life
        FOREIGN KEY  (life_id)
        REFERENCES   life(id)
);

CREATE TABLE storage_instance_pool (
    storage_instance_uuid TEXT PRIMARY KEY,
    storage_pool_uuid     TEXT NOT NULL,
    CONSTRAINT       fk_storage_instance_pool_instance
        FOREIGN KEY  (storage_instance_uuid)
        REFERENCES   storage_instance(uuid),
    CONSTRAINT       fk_storage_instance_pool_pool
        FOREIGN KEY  (storage_pool_uuid)
        REFERENCES   storage_pool(uuid)
);

-- storage_unit_owner is used to indicate when
-- a unit is the owner of a storage instance.
-- This is different to a storage attachment.
CREATE TABLE storage_unit_owner (
    storage_instance_uuid TEXT PRIMARY KEY,
    unit_uuid             TEXT NOT NULL,
    CONSTRAINT       fk_storage_owner_storage
        FOREIGN KEY  (storage_instance_uuid)
        REFERENCES   storage_instance(uuid),
    CONSTRAINT       fk_storage_owner_unit
        FOREIGN KEY  (unit_uuid)
        REFERENCES   unit(uuid)
);

-- Should owner just be a boolean on this table,
-- or can a unit be an owner without being attached?
CREATE TABLE storage_attachment (
    storage_instance_uuid TEXT PRIMARY KEY,
    unit_uuid             TEXT NOT NULL,
    CONSTRAINT       fk_storage_owner_storage
        FOREIGN KEY  (storage_instance_uuid)
        REFERENCES   storage_instance(uuid),
    CONSTRAINT       fk_storage_owner_unit
        FOREIGN KEY  (unit_uuid)
        REFERENCES   unit(uuid)
);

-- Does an instance always have constraints?



