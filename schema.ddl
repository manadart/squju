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

CREATE TABLE IF NOT EXISTS application_offer (
	uuid				TEXT PRIMARY KEY,
	name				TEXT,
	application_uuid	TEXT NOT NULL,
	-- application_description
	CONSTRAINT			fk_application_offer_application
		FOREIGN KEY		(application_uuid)
		REFERENCES		application(uuid)
);

CREATE TABLE IF NOT EXISTS endpoint_binding (
	uuid				TEXT PRIMARY KEY,
	application_uuid	TEXT NOT NULL,
	space_id			TEXT NOT NULL,
	endpoint_name		TEXT NOT NULL,
	CONSTRAINT			fk_endpoint_binding_application
		FOREIGN KEY		(application_uuid)
		REFERENCES		application(uuid)
	CONSTRAINT			fk_endpoint_binding_space
		FOREIGN KEY		(space_id)
		REFERENCES		space(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_endpoint_binding_aid_ename
ON endpoint_binding (application_uuid, endpoint_name)

/*
 * Link Layer Device
 */
CREATE TABLE IF NOT EXISTS link_layer_device (
	uuid				TEXT PRIMARY KEY,
	provider_id			TEXT,
	name				TEXT,
	mtu					INT,
	machine_id			TEXT NOT NULL,
	type				TEXT,
	macaddress			TEXT,
	is_auto_start		BOOLEAN,
	is_up				BOOLEAN,
	parent_name			TEXT,
	virtual_port_type	TEXT,
	CONSTRAINT			fk_link_layer_device_machine
		FOREIGN KEY		(machine_id)
		REFERENCES		machine(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_link_layer_device_provider_id
ON link_layer_device (provider_id);

/*
 * IP Address
 */
CREATE TABLE IF NOT EXISTS ip_address (
	uuid					TEXT PRIMARY KEY,
	provider_id				TEXT,
	provider_subnet_id		TEXT,
	device_name				TEXT,
	machine_id				TEXT NOT NULL,
	link_layer_device_uuid	TEXT NOT NULL,
	subnet_cidr				TEXT,
	config_method			TEXT,
	value					TEXT,
	gateway_address			TEXT,
	is_default_gateway		BOOLEAN,
	origin					TEXT,
	is_shadow				BOOLEAN,
	is_secondary			BOOLEAN,
	-- provider_network_id
	-- TODO: Shall we include this field, or can we drop and access via subnet?
	CONSTRAINT				fk_ip_address_subnet
		FOREIGN KEY			(provider_subnet_id)
		REFERENCES			subnet(provider_id),
	CONSTRAINT				fk_ip_address_link_layer_device
		FOREIGN KEY			(link_layer_device_uuid)
		REFERENCES			link_layer_device(uuid)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ip_address_provider_id
ON ip_address (provider_id);

CREATE TABLE IF NOT EXISTS dns_server (
	uuid					TEXT PRIMARY KEY,
	ip_address_uuid			TEXT NOT NULL,
	dns_server				TEXT,
	CONSTRAINT				fk_dns_server_ip_address
		FOREIGN KEY			(ip_address_uuid)
		REFERENCES			ip_address(uuid)
);

CREATE TABLE IF NOT EXISTS dns_search_domain (
	uuid					TEXT PRIMARY KEY,
	ip_address_uuid			TEXT NOT NULL,
	dns_search_domain		TEXT,
	CONSTRAINT				fk_dns_search_domain_ip_address
		FOREIGN KEY			(ip_address_uuid)
		REFERENCES			ip_address(uuid)
);
