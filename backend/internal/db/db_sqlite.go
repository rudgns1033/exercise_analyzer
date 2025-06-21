package db

import (
	_ "github.com/glebarez/go-sqlite"
	"github.com/glebarez/sqlite"
	"github.com/rs/zerolog/log"
	"gorm.io/gorm"
	"os"
)

func init() {
	if _, err := os.Stat("./database"); err != nil {
		os.MkdirAll("./database", 0755)
	}
	tmp, err := gorm.Open(sqlite.Open("./database/mydb.db"), &gorm.Config{})
	if err != nil {
		log.Debug().Err(err).Msg("failed to open database")
		return
	}
	db = tmp
}
