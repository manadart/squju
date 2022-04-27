package main

import (
	"database/sql"
	"log"
	"os"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	migrationFile := os.Args[1]
	dbFileName := os.Args[2]

	db, err := sql.Open("sqlite3", dbFileName)
	if err != nil {
		log.Fatal(err)
	}

	m := &migration{db, migrationFile}
	if err = m.migrate(); err != nil {
		log.Fatalln(err)
	}
}
