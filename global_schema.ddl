/*
 * Clouds
 */
CREATE TABLE IF NOT EXISTS cloud (
	uuid				TEXT PRIMARY KEY,
	name				TEXT,
	type				TEXT,
	endpoint			TEXT,
	identity_endpoint	TEXT,
	storage_endpoint	TEXT,
	skip_tls_verify		BOOLEAN
)

CREATE TABLE IF NOT EXISTS cloud_region (
	uuid				TEXT PRIMARY KEY,
	cloud_uuid			TEXT NOT NULL,
	name				TEXT,
	endpoint			TEXT,
	identity_endpoint	TEXT,
	storage_endpoint	TEXT,
	CONSTRAINT			cloud_region_cloud
		FOREIGN KEY		(cloud_uuid)
		REFERENCES		cloud(uuid)
);

CREATE TABLE IF NOT EXISTS auth_type (
	id			INT PRIMARY KEY,
	auth_type	TEXT
);

INSERT INTO auth_type VALUES
(
	0,
	"oauth1"
), (
	1,
	"userpass"
), (
	2,
	"certificate"
), (
	3,
	"access-key"
);

CREATE TABLE IF NOT EXISTS cloud_auth_type (
	uuid			TEXT PRIMARY KEY,
	cloud_uuid		TEXT NOT NULL,
	auth_type_id	INT NOT NULL,
	CONSTRAINT		fk_cloud_auth_type_cloud
		FOREIGN KEY	(cloud_uuid)
		REFERENCES	cloud(uuid),
	CONSTRAINT		fk_cloud_auth_type_auth_type
		FOREIGN KEY	(auth_type_id)
		REFERENCES	auth_type(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_cloud_auth_type_cid_atid
ON cloud_auth_type (cloud_uuid, auth_type_id);

CREATE TABLE IF NOT EXISTS ca_cert (
	uuid		TEXT PRIMARY KEY,
	ca_cert		TEXT
);

CREATE TABLE IF NOT EXISTS cloud_ca_cert (
	uuid			TEXT PRIMARY KEY,
	cloud_uuid		TEXT NOT NULL,
	ca_cert_uuid	TEXT NOT NULL,
	CONSTRAINT		fk_cloud_ca_cert_cloud
		FOREIGN KEY	(cloud_uuid)
		REFERENCES	cloud(uuid),
	CONSTRAINT		fk_cloud_ca_cert_ca_cert
		FOREIGN KEY	(ca_cert_uuid)
		REFERENCES	ca_cert(uuid)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_cloud_ca_cert_cid_ccid
ON cloud_ca_cert (cloud_uuid, ca_cert_uuid);

/*
 * Cloud Credentials
 */
CREATE TABLE IF NOT EXISTS cloud_credential (
	uuid			TEXT PRIMARY KEY,
	cloud_uuid		TEXT NOT NULL,
	name			TEXT,
	auth_type_id	INT NOT NULL,
	revoked			BOOLEAN,
	invalid			BOOLEAN,
	invalid_reason	TEXT,
	-- owner
	CONSTRAINT		fk_cloud_credential_cloud
		FOREIGN KEY	(cloud_uuid)
		REFERENCES	cloud(uuid),
	CONSTRAINT		fk_cloud_credential_auth_type
		FOREIGN KEY	(auth_type_id)
		REFERENCES	auth_type(id)
);

CREATE TABLE IF NOT EXISTS cloud_credential_attribute (
	uuid					TEXT PRIMARY KEY,
	cloud_credential_uuid	TEXT NOT NULL,
	key						TEXT,
	value					TEXT,
	CONSTRAINT				fk_cloud_credential_attribute_cloud_credential
		FOREIGN KEY			(cloud_credential_uuid)
		REFERENCES			cloud_credential(uuid)
);

/*
 * Controllers
 */
CREATE TABLE IF NOT EXISTS controller (
	uuid			TEXT PRIMARY KEY,
	cloud_uuid		TEXT NOT NULL,
	name			TEXT,
	CONSTRAINT		fk_controller_cloud
		FOREIGN KEY	(cloud_uuid)
		REFERENCES	cloud(uuid)
)

CREATE TABLE IF NOT EXISTS controller_node (
	uuid			TEXT PRIMARY KEY,
	controller_uuid	TEXT NOT NULL,
	has_vote		BOOLEAN,
	wants_vote		BOOLEAN,
	password_hash	TEXT,
	agent_version	TEXT,
	CONSTRAINT		fk_controller_node_controller
		FOREIGN KEY	(controller_uuid)
		REFERENCES	controller(uuid)
);

/*
 * Upgrade Info
 */
CREATE TABLE IF NOT EXISTS upgrade_info (
	uuid				TEXT PRIMARY KEY,
	id					TEXT NOT NULL,
	previous_version	TEXT,
	target_version		TEXT,
	status				TEXT,
	started				TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_upgrade_info_id
ON upgrade_info (id);

CREATE TABLE IF NOT EXISTS controller_node_upgrade_ready (
	uuid					TEXT PRIMARY KEY,
	controller_node_uuid	TEXT NOT NULL,
	upgrade_info_id			TEXT NOT NULL,
	CONSTRAINT				fk_upgrade_ready_controller
		FOREIGN KEY			(controller_node_uuid)
		REFERENCES			controller_node(uuid),
	CONSTRAINT				fk_upgrade_ready_upgrade_info
		FOREIGN KEY			(upgrade_info_id)
		REFERENCES			upgrade_info(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_controller_node_upgrade_ready_cnid_uiid
ON controller_node_upgrade_ready (controller_node_uuid, upgrade_info_id);

CREATE TABLE IF NOT EXISTS controller_node_upgrade_done (
	uuid					TEXT PRIMARY KEY,
	controller_node_uuid	TEXT NOT NULL,
	upgrade_info_id			TEXT NOT NULL,
	CONSTRAINT				fk_upgrade_done_controller
		FOREIGN KEY			(controller_node_uuid)
		REFERENCES			controller_node(uuid),
	CONSTRAINT				fk_upgrade_done_upgrade_info
		FOREIGN KEY			(upgrade_info_id)
		REFERENCES			upgrade_info(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_controller_node_upgrade_done_cnid_uiid
ON controller_node_upgrade_done (controller_node_uuid, upgrade_info_id);

/*
 * Models
 */
CREATE TABLE IF NOT EXISTS model (
	uuid					TEXT PRIMARY KEY,
	name					TEXT,
	type					TEXT,
	life					INT,
	controller_uuid			TEXT NOT NULL,
	migration_mode			TEXT,
	environ_version			INT,
	cloud_uuid				TEXT NOT NULL,
	cloud_region_uuid		TEXT,
	cloud_credential_uuid	TEXT,
	latest_available_tools	TEXT,
	password_hash			TEXT,
	force_destroyed			BOOLEAN,
	destroy_timeout			INT,
	controller_model		BOOLEAN,
	meter_status			TEXT,
	meter_info				TEXT,
	-- owner
	-- SLA
	CONSTRAINT				fk_model_controller
		FOREIGN KEY			(controller_uuid)
		REFERENCES			controller(uuid),
	CONSTRAINT				fk_model_cloud
		FOREIGN KEY			(cloud_uuid)
		REFERENCES			cloud(uuid),
	CONSTRAINT				fk_model_cloud_region
		FOREIGN KEY			(cloud_region_uuid)
		REFERENCES			cloud_region(uuid),
	CONSTRAINT				fk_model_cloud_credential
		FOREIGN KEY			(cloud_credential_uuid)
		REFERENCES			cloud_credential(uuid)
);

/*
 * Users
 */
CREATE TABLE IF NOT EXISTS user (
	uuid					TEXT PRIMARY KEY,
	name					TEXT NOT NULL,
	display_name			TEXT,
	deactivated				BOOLEAN,
	deleted					BOOLEAN,
	secret_key				TEXT,
	password_hash			TEXT,
	password_salt			TEXT,
	created_by_user_uuid	TEXT NOT NULL,
	date_created			TIMESTAMP,
	last_login				TIMESTAMP,
	last_login_model_uuid	TEXT NOT NULL,
	CONSTRAINT				fk_user_created_by_user
		FOREIGN KEY			(created_by_user_uuid)
		REFERENCES			user(uuid),
	CONSTRAINT				fk_user_last_login_model
		FOREIGN KEY			(last_login_model_uuid)
		REFERENCES			model(uuid)
);

CREATE INDEX IF NOT EXISTS idx_user_name
ON user (name)

CREATE TABLE IF NOT EXISTS user_controller_access (
	uuid			TEXT PRIMARY KEY,
	user_uuid		TEXT NOT NULL,
	controller_uuid TEXT NOT NULL,
	CONSTRAINT		fk_user_controller_access_user
		FOREIGN KEY	(user_uuid)
		REFERENCES	user(uuid),
	CONSTRAINT		fk_user_controller_access_controller
		FOREIGN KEY	(controller_uuid)
		REFERENCES	controller(uuid)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_controller_access_uid_cid
ON user_controller_access (user_uuid, controller_uuid);

/*
 * Model Migrations
 */
CREATE TABLE IF NOT EXISTS migration (
	uuid					TEXT PRIMARY KEY,
	model_uuid				TEXT NOT NULL,
	attempt					INT,
	initiated_by_user_id	TEXT NOT NULL,
	target_controller_uuid	TEXT NOT NULL,
	target_cacert			TEXT,
	target_entity			TEXT,
	target_password			TEXT,
	target_macaroons		TEXT,
	active					BOOLEAN,
	start_time				TIMESTAMP,
	success_time			TIMESTAMP,
	end_time				TIMESTAMP,
	phase					TEXT,
	phase_changed_time		TIMESTAMP,
	status_message			TEXT,
	-- target_controller_alias
	-- target_addresses
	CONSTRAINT				fk_migration_model
		FOREIGN KEY			(model_uuid)
		REFERENCES			model(uuid),
	CONSTRAINT				fk_migration_initiated_by_user
		FOREIGN KEY			(initiated_by_user_id)
		REFERENCES			user(uuid)
	CONSTRAINT				fk_migration_target_controller
		FOREIGN KEY			(target_controller_uuid)
		REFERENCES			controller(uuid)
);

CREATE TABLE IF NOT EXISTS migration_minion_sync (
	uuid			TEXT PRIMARY KEY,
	migration_uuid	TEXT NOT NULL,
	phase			TEXT,
	entity_key		TEXT,
	time			TIMESTAMP,
	success			BOOLEAN,
	CONSTRAINT		fk_migration_minion_sync_migration
		FOREIGN KEY	(migration_uuid)
		REFERENCES	migration(uuid)
);

/*
 * Global Settings
 */
CREATE TABLE IF NOT EXISTS global_setting (
	uuid			TEXT PRIMARY KEY,
	name			TEXT NOT NULL,
	value			TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_global_setting_name
ON global_setting (name);

/*
 * Autocert Cache
 */
CREATE TABLE IF NOT EXISTS autocert_cache (
	uuid			TEXT PRIMARY KEY,
	name			TEXT
);
