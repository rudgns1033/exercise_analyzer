package main

import (
	"arnold/internal/api"
	"arnold/pkg/logger"
	"github.com/rs/zerolog/log"
	"net/http"
)

func main() {
	logger.Init()
	mux := http.NewServeMux()
	s := api.NewServer()
	s.SetHandlers(mux)
	go http.ListenAndServe(":8080", mux)
	log.Debug().Msgf("Listening on port 8080")
	select {}
}
