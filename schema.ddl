/*
 * Machine
 */
CREATE TABLE IF NOT EXISTS machine (
	uuid						TEXT PRIMARY KEY,
	id							TEXT NOT NULL,
	nonce						TEXT,
	series						TEXT,
	container_type				TEXT,
	life						INT,
	password_hash				TEXT,
	clean						BOOLEAN,
	force_destroyed				BOOLEAN,
	preferred_public_address	TEXT,
	preferred_private_address	TEXT,
	supported_containers_known	BOOLEAN,
	placement					TEXT,
	agent_started_at			TEXT,
	hostname					TEXT
	-- principles
	-- tools
	-- jobs
	-- addresses
	-- machine_addresses
	-- supported_containers
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machine_id
ON machine (id);

/*
 * File system
 */
CREATE TABLE IF NOT EXISTS filesystem (
	uuid				TEXT PRIMARY KEY,
	id					TEXT NOT NULL,
	releasing			BOOLEAN,
	life				INT
	-- storage_id
	-- volume_id
	-- info
	-- params
	-- host_id
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_filesystem_id
ON filesystem (id)

-- TODO: This comes from the `filesystems` attribute of machine.
-- How does this differ to `filesystem_attachment`?
CREATE TABLE IF NOT EXISTS machine_filesystem (
	uuid			TEXT PRIMARY KEY,
	machine_id		TEXT NOT NULL,
	filesystem_id	TEXT NOT NULL,
	CONSTRAINT		fk_machine_filesystem_machine
		FOREIGN KEY	(machine_id)
		REFERENCES	machine(id),
	CONSTRAINT		fk_machine_filesystem_filesystem
		FOREIGN KEY	(filesystem_id)
		REFERENCES	filesystem(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machine_filesystem_mid_fid
ON machine_filesystem (machine_id, filesystem_id);

/*
 * Volume
 */
CREATE TABLE IF NOT EXISTS volume (
	uuid				TEXT PRIMARY KEY,
	id					TEXT NOT NULL,
	life				INT,
	releasing			BOOLEAN
	-- storage_id
	-- info
	-- params
	-- host_id
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_volume_id
ON volume (id);

-- TODO: This comes from the `volumes` attribute of machine.
-- How does this differ to `volume_attachments`?
CREATE TABLE IF NOT EXISTS machine_volume (
	uuid			TEXT PRIMARY KEY,
	machine_id		TEXT NOT NULL,
	volume_id		TEXT NOT NULL,
	CONSTRAINT		fk_machine_volume_machine
		FOREIGN KEY	(machine_id)
		REFERENCES	machine(id),
	CONSTRAINT		fk_machine_volume_volume
		FOREIGN KEY	(volume_id)
		REFERENCES	volume(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machine_volume_mid_vid
ON machine_volume (machine_id, volume_id);

/*
 * Space
 */
CREATE TABLE IF NOT EXISTS space (
	uuid			TEXT PRIMARY KEY,
	id				TEXT NOT NULL,
	life			INT,
	name			TEXT,
	is_public		BOOLEAN,
	provider_id		TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_space_provider_id
ON space (provider_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_space_id
ON space (id);

/*
 * Network
 */
CREATE TABLE IF NOT EXISTS network (
	uuid		TEXT PRIMARY KEY,
	provider_id	TEXT ,
	name		TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_network_provider_id
ON network (provider_id)

/*
 * Subnet
 */
CREATE TABLE IF NOT EXISTS subnet (
	uuid				TEXT PRIMARY KEY,
	id					TEXT NOT NULL,
	life				INT,
	provider_id			TEXT,
	provider_network_id TEXT ,
	cidr				TEXT,
	vlantag				INT,
	is_public			BOOLEAN,
	space_id			TEXT NOT NULL,
	fan_local_underlay	TEXT,
	fan_overlay			TEXT,
	-- availability_zones
	CONSTRAINT			fk_subnet_space
		FOREIGN KEY		(space_id)
		REFERENCES		space(id),
	CONSTRAINT			fk_subnet_network
		FOREIGN KEY		(provider_network_id)
		REFERENCES		network(provider_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_subnet_provider_id
ON subnet (provider_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_subnet_id
ON subnet (id);

/*
 * Application
 */
CREATE TABLE IF NOT EXISTS application (
	uuid					TEXT PRIMARY KEY,
	id						TEXT NOT NULL,
	name					TEXT,
	series					TEXT,
	subordinate				BOOLEAN,
	charm_url				TEXT,
	channel					TEXT,
	charm_origin			TEXT,
	charm_modified_version	INT,
	force_charm				BOOLEAN,
	life					INT,
	min_units				INT,
	exposed					BOOLEAN,
	desired_scale			INT,
	password_hash			TEXT,
	placement				TEXT,
	has_resources			BOOL
	-- unit_count
	-- relation_count
	-- tools
	-- metric_credentials
	-- exposed_endpoints
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_application_id
ON application (id);

CREATE TABLE IF NOT EXISTS application_offer (
	uuid			TEXT PRIMARY KEY,
	id				TEXT NOT NULL,
	name			TEXT,
	application_id	TEXT NOT NULL,
	-- application_description
	CONSTRAINT		fk_application_offer_application
		FOREIGN KEY	(application_id)
		REFERENCES	application(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_application_offer_id
ON application_offer (id)

CREATE TABLE IF NOT EXISTS endpoint_binding (
	uuid			TEXT PRIMARY KEY,
	application_id	TEXT NOT NULL,
	space_id		TEXT NOT NULL,
	endpoint_name	TEXT NOT NULL,
	CONSTRAINT		fk_endpoint_binding_application
		FOREIGN KEY	(application_id)
		REFERENCES	application(id),
	CONSTRAINT		fk_endpoint_binding_space
		FOREIGN KEY	(space_id)
		REFERENCES	space(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_endpoint_binding_aid_ename
ON endpoint_binding (application_id, endpoint_name)
