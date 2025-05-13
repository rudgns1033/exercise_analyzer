package db

import (
	"encoding/json"
	"fmt"
	"gorm.io/gorm"
	"time"
)

var db *gorm.DB

type Model struct {
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
}
type User struct {
	Model

	ID       int  `json:"id" gorm:"primarykey"`
	Height   int  `json:"height"`
	Weight   int  `json:"weight"`
	Age      int  `json:"age"`
	Beginner bool `json:"beginner"`

	UserName string `json:"user_name,omitempty"`
	//UserID   string `json:"user_id,omitempty"`
	Day int `json:"day,omitempty"`

	PlanID       int
	ExercisePlan Plan           `gorm:"foreignKey:PlanID"`
	Exercise     ExerciseResult `gorm:""`
}

func (u *User) JSON() ([]byte, error) {
	b, err := json.Marshal(u)
	if err != nil {
		return nil, fmt.Errorf(`json marshal err: %w`, err)
	}
	return b, nil
}

type ExerciseResult struct {
	Model

	Day1 bool
	Day2 bool
	Day3 bool
	Day4 bool
	Day5 bool
	Day6 bool
	Day7 bool
}

// GetUser user id 로 유저를 반환하는 함수
func GetUser(userID int) User {
	u := User{ID: userID}
	db.Find(&u)
	return u
}

func init() {
	db = &gorm.DB{}
}

type Plan struct {
	ID int `json:"id" gorm:"primarykey"`
	Model

	UserID         int    `json:"user_id" gorm:"-"`
	DailyType      string `json:"daily_exercise_type"`
	DailyReps      int    `json:"daily_exercise_repit"`
	DailyDuration  int    `json:"daily_exercise_duration"`
	WeeklyType     string `json:"weekly_exercise_type"`
	WeeklyDuration int    `json:"weekly_exercise_duration"`
}

func (p *Plan) JSON() ([]byte, error) {
	b, err := json.Marshal(p)
	if err != nil {
		return nil, fmt.Errorf(`json marshal err: %w`, err)
	}
	return b, nil
}

//
