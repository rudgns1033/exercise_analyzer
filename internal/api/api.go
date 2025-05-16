package api

import (
	"arnold/internal/core"
	"arnold/internal/db"
	"encoding/json"
	"fmt"
	"github.com/rs/zerolog/log"
	"net/http"
)

type server struct {
}

func NewServer() *server {
	return &server{}
}
func (s *server) SetHandlers(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/users", s.getUser)
	mux.HandleFunc("POST /api/users", s.setUser)
	mux.HandleFunc("GET /api/ws", s.serveWs)
	mux.HandleFunc("POST /api/plans", s.setPlan)
	mux.HandleFunc("POST /api/analyze", s.analyze)
}

func (s *server) getUser(w http.ResponseWriter, r *http.Request) {
	user := db.User{}

	json.NewDecoder(r.Body).Decode(&user)
	defer r.Body.Close()

	db.GetUser(user.ID)
}

func (s *server) setUser(w http.ResponseWriter, r *http.Request) {
	user := db.User{}
	json.NewDecoder(r.Body).Decode(&user)
	defer r.Body.Close()

	log.Debug().Msgf("Setting user: %v", user)
	w.Header().Set("Content-Type", "application/json")

	userJson, err := user.JSON()
	if err != nil {

		w.WriteHeader(http.StatusNonAuthoritativeInfo)
		w.Write([]byte(`{"message":"json marshal err"}`))
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Write(userJson)
	return
}

func (s *server) setPlan(w http.ResponseWriter, r *http.Request) {
	plan := db.Plan{}
	json.NewDecoder(r.Body).Decode(&plan)
	defer r.Body.Close()

	log.Debug().Msgf("Setting plan: %v", plan)
	w.Header().Set("Content-Type", "application/json")

	planJson, err := plan.JSON()
	if err != nil {

		w.WriteHeader(http.StatusNonAuthoritativeInfo)
		w.Write([]byte(`{"message":"json marshal err"}`))
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Write(planJson)
	return
}

func (s *server) analyze(w http.ResponseWriter, r *http.Request) {
	frameData := core.FrameData{}
	if err := json.NewDecoder(r.Body).Decode(&frameData); err != nil {
		log.Debug().Msgf("Analyze err: %v", err)
	}
	defer r.Body.Close()

	log.Debug().Msgf("frameData: %v", frameData)
	w.Header().Set("Content-Type", "application/json")

	feedback := core.Feedback{
		Correct:        false,
		FeedBack:       core.PUSHUP_ELBOW,
		CaloriesBurned: 1,
	}

	feedbackJson, err := feedback.JSON()
	if err != nil {
		w.WriteHeader(http.StatusNonAuthoritativeInfo)
		w.Write([]byte(`{"message":"json marshal err"}`))
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Write(feedbackJson)
	return
}

func (s *server) serveWs(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {

	}
	// auth()
	//wsServer := NewWSServer(conn)

	go func() {

	}()

	fmt.Println(conn)
}
