CREATE TABLE IF NOT EXISTS machine (
	uuid 			TEXT PRIMARY KEY,
	id 				TEXT NOT NULL UNIQUE,
	nonce 			TEXT,
	series 			TEXT,
	container_type	TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machine_id
ON machine (id);

CREATE TABLE IF NOT EXISTS filesystem (
	uuid 			TEXT PRIMARY KEY,
	id 				TEXT NOT NULL UNIQUE,
	releasing		BOOLEAN
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_filesystem_id
ON filesystem (id)

CREATE TABLE IF NOT EXISTS machine_filesystem (
	uuid 			TEXT PRIMARY KEY,
	machine_id		TEXT NOT NULL,
	filesystem_id	TEXT NOT NULL,
	CONSTRAINT 		fk_machine_filesystem_machine
		FOREIGN KEY (machine_id)
		REFERENCES 	machine(id),
	CONSTRAINT 		fk_machine_filesystem_filesystem
		FOREIGN KEY (filesystem_id)
		REFERENCES 	filesystem(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machine_filesystem_mid_fid
ON machine_filesystem (machine_id, filesystem_id);

CREATE TABLE IF NOT EXISTS space (
	uuid			TEXT PRIMARY KEY,
	id				TEXT NOT NULL UNIQUE,
	life			INT,
	name			TEXT,
	is_public		BOOLEAN,
	provider_id		TEXT,
	CONSTRAINT		fk_space_provider
		FOREIGN KEY	(provider_id)
		REFERENCES  provider(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_space_provider_id
ON space (provider_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_space_id
ON space (id);

CREATE TABLE IF NOT EXISTS subnet (
	uuid				TEXT PRIMARY KEY,
	id					TEXT NOT NULL UNIQUE,
	life				INT,
	provider_id			TEXT,
	provider_network_id	TEXT,
	cidr				TEXT,
	vlantag				INT,
	is_public			BOOLEAN,
	space_id			TEXT NOT NULL,
	fan_local_underlay	TEXT,
	fan_overlay			TEXT,
	CONSTRAINT			fk_subnet_space
		FOREIGN KEY		(space_id)
		REFERENCES		space(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_subnet_provider_id
ON subnet (provider_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_subnet_id
ON subnet (id);
