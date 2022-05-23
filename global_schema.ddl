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

CREATE TABLE IF NOT EXISTS api_host_port (
	uuid			TEXT PRIMARY KEY,
	value			TEXT,
	address_type	TEXT,
	scope			TEXT,
	port			INT,
	space_id		TEXT, -- TODO: Investigate this field
	agent_useable	BOOL,
	controller_uuid	TEXT NOT NULL,
	CONSTRAINT		fk_api_host_port_controller
		FOREIGN KEY	(controller_uuid)
		REFERENCES	controller(uuid)
);

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

CREATE TABLE IF NOT EXISTS state_serving_info (
	uuid			TEXT PRIMARY KEY,
	controller_uuid	TEXT NOT NULL,
	api_port		INT,
	state_port		INT,
	cert			TEXT,
	private_key		TEXT,
	ca_private_key	TEXT,
	shared_secret	TEXT,
	system_identity	TEXT,
	CONSTRAINT		fk_state_serving_info_controller
		FOREIGN KEY	(controller_uuid)
		REFERENCES	controller(uuid)
);

/*
 * External Controllers
 */
CREATE TABLE IF NOT EXISTS external_controller (
	uuid			TEXT PRIMARY KEY,
	alias			TEXT,
	ca_cert_uuid	TEXT,
	CONSTRAINT		fk_external_controller_controller
		FOREIGN KEY	(uuid)
		REFERENCES	controller(uuid)
);

CREATE TABLE IF NOT EXISTS external_controller_address (
	uuid						TEXT PRIMARY KEY,
	address						TEXT,
	external_controller_uuid	TEXT NOT NULL,
	CONSTRAINT					fk_external_controller_address_external_controller
		FOREIGN KEY				(external_controller_uuid)
		REFERENCES				external_controller(uuid)
);

/*
 * Upgrade Info
 */
CREATE TABLE IF NOT EXISTS upgrade_status (
	id		INT PRIMARY KEY,
	status	TEXT
);

INSERT INTO upgrade_status VALUES
(
	0,
	"pending"
), (
	1,
	"db-complete"
), (
	2,
	"running"
), (
	3,
	"complete"
), (
	4,
	"aborted"
);

CREATE TABLE IF NOT EXISTS upgrade_info (
	uuid				TEXT PRIMARY KEY,
	controller_uuid		TEXT NOT NULL,
	previous_version	TEXT,
	target_version		TEXT,
	status_id			INT NOT NULL,
	started				TIMESTAMP,
	CONSTRAINT			fk_upgrade_info_controller
		FOREIGN KEY		(controller_uuid)
		REFERENCES		controller(uuid),
	CONSTRAINT			fk_upgrade_info_status
		FOREIGN KEY		(status_id)
		REFERENCES		upgrade_status(id)
);

CREATE INDEX IF NOT EXISTS idx_upgrade_info_cid
ON upgrade_info (controller_uuid);

CREATE TABLE IF NOT EXISTS controller_node_upgrade_ready (
	uuid					TEXT PRIMARY KEY,
	controller_node_uuid	TEXT NOT NULL,
	upgrade_info_uuid		TEXT NOT NULL,
	CONSTRAINT				fk_upgrade_ready_controller
		FOREIGN KEY			(controller_node_uuid)
		REFERENCES			controller_node(uuid),
	CONSTRAINT				fk_upgrade_ready_upgrade_info
		FOREIGN KEY			(upgrade_info_uuid)
		REFERENCES			upgrade_info(uuid)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_controller_node_upgrade_ready_cnid_uiid
ON controller_node_upgrade_ready (controller_node_uuid, upgrade_info_uuid);

CREATE TABLE IF NOT EXISTS controller_node_upgrade_done (
	uuid					TEXT PRIMARY KEY,
	controller_node_uuid	TEXT NOT NULL,
	upgrade_info_uuid		TEXT NOT NULL,
	CONSTRAINT				fk_upgrade_done_controller
		FOREIGN KEY			(controller_node_uuid)
		REFERENCES			controller_node(uuid),
	CONSTRAINT				fk_upgrade_done_upgrade_info
		FOREIGN KEY			(upgrade_info_uuid)
		REFERENCES			upgrade_info(uuid)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_controller_node_upgrade_done_cnid_uiid
ON controller_node_upgrade_done (controller_node_uuid, upgrade_info_uuid);

/*
 * Restore Info
 */
CREATE TABLE IF NOT EXISTS restore_status (
	id		INT PRIMARY KEY,
	status	TEXT
);

INSERT INTO restore_status VALUES
(
	0,
	"NOT-RESTORING"
), (
	1,
	"PENDING"
), (
	2,
	"RESTORING"
), (
	3,
	"RESTORED"
), (
	4,
	"CHECKED"
), (
	5,
	"FAILED"
);

CREATE TABLE IF NOT EXISTS restore_info (
	uuid			TEXT PRIMARY KEY,
	controller_uuid	TEXT NOT NULL,
	status_id		INT NOT NULL,
	CONSTRAINT			fk_restore_info_controller
		FOREIGN KEY		(controller_uuid)
		REFERENCES		controller(uuid)
	CONSTRAINT			fk_restore_info_status
		FOREIGN KEY		(status_id)
		REFERENCES		restore_status(id)
);

CREATE INDEX IF NOT EXISTS idx_restore_info_cid
ON restore_info (controller_uuid);

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
	created_by_user_uuid	TEXT,
	date_created			TIMESTAMP,
	last_login				TIMESTAMP,
	last_login_model_uuid	TEXT, -- Not constrained to avoid circular reference
	CONSTRAINT				fk_user_created_by_user
		FOREIGN KEY			(created_by_user_uuid)
		REFERENCES			user(uuid)
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
 * User Permissions
 */
CREATE TABLE IF NOT EXISTS access_type (
	id			INT PRIMARY KEY,
	access_type		TEXT
);

INSERT INTO access_type VALUES
(
	0,
	""
), (
	1,
	"read"
), (
	2,
	"write"
), (
	3,
	"consume"
), (
	4,
	"admin"
), (
	5,
	"login"
), (
	6,
	"add-model"
), (
	7,
	"superuser"
);

CREATE TABLE IF NOT EXISTS permission (
	uuid				TEXT PRIMARY KEY,
	model_uuid			TEXT NOT NULL,
	user_uuid			TEXT NOT NULL,
	access_type_id			INT NOT NULL,
	CONSTRAINT			fk_permission_model
		FOREIGN KEY		(model_uuid)
		REFERENCES		model(uuid),
	CONSTRAINT			fk_permission_user
		FOREIGN KEY		(user_uuid)
		REFERENCES		user(uuid),
	CONSTRAINT			fk_permission_access_type
		FOREIGN KEY		(access_type_id)
		REFERENCES		access_type(id)
);

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
	owner_uuid		TEXT NOT NULL,
	CONSTRAINT		fk_cloud_credential_cloud
		FOREIGN KEY	(cloud_uuid)
		REFERENCES	cloud(uuid),
	CONSTRAINT		fk_cloud_credential_auth_type
		FOREIGN KEY	(auth_type_id)
		REFERENCES	auth_type(id)
	CONSTRAINT		fk_cloud_credential_owner
		FOREIGN KEY	(owner_uuid)
		REFERENCES	user(uuid)
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
 * Models
 */
CREATE TABLE IF NOT EXISTS sla (
	id			INT PRIMARY KEY,
	level		TEXT
);

INSERT INTO sla VALUES
(
	0,
	"unsupported"
), (
	1,
	"essential"
), (
	2,
	"standard"
), (
	3,
	"advanced"
);

CREATE TABLE IF NOT EXISTS model (
	uuid						TEXT PRIMARY KEY,
	name						TEXT,
	type						TEXT,
	life						INT,
	owner_uuid					TEXT NOT NULL,
	controller_uuid				TEXT NOT NULL,
	external_controller_uuid	TEXT,
	migration_mode				TEXT,
	environ_version				INT,
	cloud_uuid					TEXT NOT NULL,
	cloud_region_uuid			TEXT,
	cloud_credential_uuid		TEXT,
	latest_available_tools		TEXT,
	sla_id						INT,
	meter_status				TEXT,
	meter_info					TEXT,
	password_hash				TEXT,
	force_destroyed				BOOLEAN,
	destroy_timeout				INT,
	controller_model			BOOLEAN,
	CONSTRAINT					fk_model_owner
		FOREIGN KEY				(owner_uuid)
		REFERENCES				user(uuid),
	CONSTRAINT					fk_model_controller
		FOREIGN KEY				(controller_uuid)
		REFERENCES				controller(uuid),
	CONSTRAINT					fk_model_external_controller
		FOREIGN KEY				(external_controller_uuid)
		REFERENCES				external_controller(uuid)
	CONSTRAINT					fk_model_cloud
		FOREIGN KEY				(cloud_uuid)
		REFERENCES				cloud(uuid),
	CONSTRAINT					fk_model_cloud_region
		FOREIGN KEY				(cloud_region_uuid)
		REFERENCES				cloud_region(uuid),
	CONSTRAINT					fk_model_cloud_credential
		FOREIGN KEY				(cloud_credential_uuid)
		REFERENCES				cloud_credential(uuid),
	CONSTRAINT					fk_model_sla
		FOREIGN KEY				(sla_id)
		REFERENCES				sla(id)
);

-- This unique index exists to ensure that two models,
-- owned by the same user, cannot have the same name
CREATE UNIQUE INDEX IF NOT EXISTS idx_model_name_oid
ON model (name, owner_uuid);

/*
 * Model Migrations
 */
CREATE TABLE IF NOT EXISTS migration (
	uuid					TEXT PRIMARY KEY,
	model_uuid				TEXT NOT NULL,
	attempt					INT,
	initiated_by_user_uuid	TEXT NOT NULL,
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
		FOREIGN KEY			(initiated_by_user_uuid)
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
 * Metrics
 */
CREATE TABLE IF NOT EXISTS metrics_batch (
	uuid			TEXT PRIMARY KEY,
	model_uuid		TEXT NOT NULL,
	unit			TEXT,
	charm_url		TEXT,
	sent			BOOLEAN,
	delete_time		TIMESTAMP,
	created			TIMESTAMP,
	credentials		TEXT,
	sla_credential	TEXT,
	CONSTRAINT		fk_metrics_batch_model
		FOREIGN KEY	(model_uuid)
		REFERENCES	model(uuid)
);

CREATE TABLE IF NOT EXISTS metric (
	uuid				TEXT PRIMARY KEY,
	metrics_batch_uuid	TEXT NOT NULL,
	key					TEXT,
	value				TEXT,
	time				TIMESTAMP,
	CONSTRAINT			fk_metric_metric_batch
		FOREIGN KEY		(metrics_batch_uuid)
		REFERENCES		metrics_batch(uuid)
);

CREATE TABLE IF NOT EXISTS metric_label (
	uuid			TEXT PRIMARY KEY,
	metric_uuid		TEXT NOT NULL,
	key				TEXT,
	value			TEXT,
	CONSTRAINT		fk_metric_label_metric
		FOREIGN KEY	(metric_uuid)
		REFERENCES	metric(uuid)
);

CREATE TABLE IF NOT EXISTS metric_manager (
	uuid					TEXT PRIMARY KEY,
	last_successful_send	TIMESTAMP,
	consecutive_errors		INT,
	grace_period			INT
);

/*
 * Leases
 */
CREATE TABLE IF NOT EXISTS lease_type (
	id		INT PRIMARY KEY,
	type	TEXT
);

INSERT INTO lease_type VALUES
(
	0,
	"controller"
), (
	1,
	"model"
), (
	2,
	"application"
);

CREATE TABLE IF NOT EXISTS lease (
	uuid			TEXT PRIMARY KEY,
	lease_type_id	INT NOT NULL,
	name			TEXT,
	holder			TEXT,
	start			TIMESTAMP,
	duration		INT,
	pinned			BOOLEAN,
	CONSTRAINT		fk_lease_lease_type
		FOREIGN KEY	(lease_type_id)
		REFERENCES	lease_type(id)
);

/*
 * Settings
 */
CREATE TABLE IF NOT EXISTS settings_group (
	uuid			TEXT PRIMARY KEY,
	group_name		TEXT
);

CREATE TABLE IF NOT EXISTS settings_value (
	uuid				TEXT PRIMARY KEY,
	settings_group_uuid	TEXT NOT NULL,
	key					TEXT,
	value				TEXT,
	CONSTRAINT			fk_setting_settings_group
		FOREIGN KEY		(settings_group_uuid)
		REFERENCES		settings_group(uuid)
);

CREATE INDEX IF NOT EXISTS idx_setting_sbid
ON settings_value (settings_group_uuid);

/*
 * Autocert Cache
 */
CREATE TABLE IF NOT EXISTS autocert_cache (
	uuid			TEXT PRIMARY KEY,
	name			TEXT
);
