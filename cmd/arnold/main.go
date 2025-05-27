package main

import (
	"arnold/internal/api"
	"arnold/internal/db"
	"arnold/pkg/logger"
	"github.com/rs/zerolog/log"
)

func main() {
	logger.Init()
	s := api.NewApp()
	s.SetHandlers()
	log.Debug().Msgf("Listening on port 8080")
	db.Init()
	s.ListenAndServe(":8080")
}
