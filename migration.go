package main

import (
	"database/sql"
	"io/ioutil"
	"log"
	"strings"
)

type migration struct {
	db            *sql.DB
	migrationFile string
}

func (m *migration) migrate() error {
	txn, err := m.db.Begin()
	if err != nil {
		return err
	}

	stmts, err := m.statements()
	if err != nil {
		return err
	}

	for _, stmt := range stmts {
		log.Printf("Running statement:\n%s\n\n", stmt)

		if _, err := txn.Exec(stmt); err != nil {
			_ = txn.Rollback()
			log.Fatalln(err)
		}
	}

	if err := txn.Commit(); err != nil {
		log.Fatalln(err)
	}

	log.Println("Migration successfully applied.")
	return nil
}

func (m *migration) statements() ([]string, error) {
	bytes, err := ioutil.ReadFile(m.migrationFile)
	if err != nil {
		return nil, err
	}
	stmts := strings.Split(string(bytes), "\n\n")
	return stmts, nil
}
