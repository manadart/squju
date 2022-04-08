CREATE TABLE IF NOT EXISTS machine (
	uuid 			TEXT PRIMARY KEY,
	id 				TEXT NOT NULL UNIQUE,
	nonce 			TEXT,
	series 			TEXT,
	container_type	TEXT
);

CREATE UNIQUE INDEX idx_machine_id
ON machine (id);

CREATE TABLE IF NOT EXISTS filesystem (
	uuid 			TEXT PRIMARY KEY,
	id 				TEXT NOT NULL UNIQUE,
	releasing		BOOLEAN
);

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

CREATE UNIQUE INDEX idx_machine_filesystem_mid_fid
ON machine_filesystem (machine_id, filesystem_id);
