package api

import (
	"arnold/internal/core"
	"arnold/internal/db"
	"encoding/json"
	"fmt"
	"github.com/rs/zerolog/log"
	"io"
	"net/http"
	"strconv"
)

// Middleware type as before
type Middleware func(http.Handler) http.Handler

// App struct to hold our routes and middleware
type App struct {
	mux         *http.ServeMux
	middlewares []Middleware
}

// NewApp creates and returns a new App with an initialized ServeMux and middleware slice
func NewApp() *App {
	return &App{
		mux:         http.NewServeMux(),
		middlewares: []Middleware{},
	}
}

// Use adds middleware to the chain
func (a *App) Use(mw Middleware) {
	a.middlewares = append(a.middlewares, mw)
}

// Handle registers a handler for a specific route, applying all middleware
func (a *App) Handle(pattern string, handler http.Handler) {
	finalHandler := handler
	for i := len(a.middlewares) - 1; i >= 0; i-- {
		finalHandler = a.middlewares[i](finalHandler)
	}
	a.mux.Handle(pattern, finalHandler)
}

// ListenAndServe starts the application server
func (a *App) ListenAndServe(address string) error {
	return http.ListenAndServe(address, a.mux)
}

func (a *App) SetHandlers() {
	a.mux.HandleFunc("GET /api/users/{id}", getUser)
	a.mux.HandleFunc("POST /api/users", setUser)

	a.mux.HandleFunc("GET /api/plans/{id}", getPlan)
	a.mux.HandleFunc("POST /api/plans", setPlan)

	a.mux.HandleFunc("GET /api/exercise_record/{id}", getRecord)
	//a.mux.HandleFunc("POST /api/exercise_record", setRecord)

	a.mux.HandleFunc("POST /api/analyze", analyze)
	a.mux.HandleFunc("GET /api/ws", serveWs)
}

func getUser(w http.ResponseWriter, r *http.Request) {
	user := db.User{}

	json.NewDecoder(r.Body).Decode(&user)
	defer r.Body.Close()

	db.GetUser(user.ID)
}

func setUser(w http.ResponseWriter, r *http.Request) {
	var user db.User

	json.NewDecoder(r.Body).Decode(&user)
	defer r.Body.Close()

	log.Debug().Msgf("Setting user: %+v", user)
	w.Header().Set("Content-Type", "application/json")
	_, err := db.GetUser(user.ID)
	if err != nil {
		log.Debug().Err(err).Msg("Failed to get user")
		//w.WriteHeader(http.StatusNonAuthoritativeInfo)
		//w.Write([]byte(`{"message":"json marshal err"}`))
		//return
	} else {

	}
	log.Debug().Msgf("set user: %+v", user.Update())

	userJson, err := user.JSON()
	w.WriteHeader(http.StatusCreated)
	w.Write(userJson)
	return
}

func getPlan(w http.ResponseWriter, r *http.Request) {
	var userID int
	var user db.User

	io.Copy(io.Discard, r.Body)
	defer r.Body.Close()

	tmpID := r.PathValue("id")

	if tmpID == "" {
		if tmp, err := strconv.Atoi(tmpID); err == nil {
			userID = tmp
		}
	}
	user.ID = userID

	log.Debug().Msgf("Getting user plan: %+v", user)
	w.Header().Set("Content-Type", "application/json")

	planJson, err := user.ExercisePlan.JSON()
	if err != nil {
		w.WriteHeader(http.StatusNonAuthoritativeInfo)
		w.Write([]byte(`{"message":"json marshal err"}`))
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Write(planJson)
	return
}

func setPlan(w http.ResponseWriter, r *http.Request) {
	plan := db.Plan{}
	json.NewDecoder(r.Body).Decode(&plan)
	defer r.Body.Close()

	log.Debug().Msgf("Setting plan: %+v", plan)
	w.Header().Set("Content-Type", "application/json")

	planJson, err := plan.JSON()
	if err != nil {
		w.WriteHeader(http.StatusNonAuthoritativeInfo)
		w.Write([]byte(`{"message":"json marshal err"}`))
		return
	}
	user, err := db.GetUser(plan.UserID)
	if err != nil {
		log.Debug().Err(err).Msgf("Error getting user: %+v", plan.UserID)
		w.WriteHeader(http.StatusBadRequest)
		w.Write(planJson)
		return
	}
	plan.ID = user.ExercisePlan.ID
	if err := plan.Update(); err != nil {
		log.Debug().Err(err).Msgf("Error updating plan: %+v", plan)
	}

	w.WriteHeader(http.StatusCreated)
	w.Write(planJson)
	return
}

func analyze(w http.ResponseWriter, r *http.Request) {
	frameData := core.FrameData{}
	if err := json.NewDecoder(r.Body).Decode(&frameData); err != nil {
		log.Debug().Msgf("Analyze err: %+v", err)
	}
	defer r.Body.Close()

	log.Debug().Msgf("frameData: %+v", frameData)
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

func serveWs(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {

	}
	// auth()
	//wsServer := NewWSServer(conn)

	go func() {

	}()

	fmt.Println(conn)
}

func getRecord(w http.ResponseWriter, r *http.Request) {
	var userID int
	var user db.User

	io.Copy(io.Discard, r.Body)
	defer r.Body.Close()

	tmpID := r.PathValue("id")

	if tmpID == "" {
		if tmp, err := strconv.Atoi(tmpID); err == nil {
			userID = tmp
		}
	}
	user.ID = userID

	log.Debug().Msgf("Getting user plan: %+v", user)
	w.Header().Set("Content-Type", "application/json")

	recordJson, err := user.ExerciseRecord.JSON()
	if err != nil {
		w.WriteHeader(http.StatusNonAuthoritativeInfo)
		w.Write([]byte(`{"message":"json marshal err"}`))
		return
	}
	w.WriteHeader(http.StatusCreated)
	w.Write(recordJson)
	return
}

//
//func setRecord(w http.ResponseWriter, r *http.Request) {
//	var record db.Record
//	json.NewDecoder(r.Body).Decode(&record)
//	defer r.Body.Close()
//
//	log.Debug().Msgf("Setting plan: %+v", record)
//	w.Header().Set("Content-Type", "application/json")
//
//	recordJson, err := record.JSON()
//	if err != nil {
//		w.WriteHeader(http.StatusNonAuthoritativeInfo)
//		w.Write([]byte(`{"message":"json marshal err"}`))
//		return
//	}
//	user, err := db.GetUser(record.UserID)
//	if err != nil {
//		log.Debug().Err(err).Msgf("Error getting user: %+v", record.UserID)
//		w.WriteHeader(http.StatusBadRequest)
//		w.Write(planJson)
//		return
//	}
//	record.ID = user.ExerciseRecord.ID
//	if err := record.Update(); err != nil {
//		log.Debug().Err(err).Msgf("Error updating plan: %+v", record)
//	}
//
//	w.WriteHeader(http.StatusCreated)
//	w.Write(recordJson)
//	return
//}
