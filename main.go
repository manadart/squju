package main

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

const fileName = "sqlite.db"

func main() {
	db, err := sql.Open("sqlite3", fileName)
	if err != nil {
		log.Fatal(err)
	}

	m := &migration{db}
	if err = m.migrate(); err != nil {
		log.Fatalln(err)
	}
}
