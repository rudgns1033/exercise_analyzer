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

	ID       int  `json:"id" gorm:"primaryKey"`
	Height   int  `json:"height"`
	Weight   int  `json:"weight"`
	Age      int  `json:"age"`
	Beginner bool `json:"beginner"`

	UserName string `json:"user_name,omitempty"`
	//UserID   string `json:"user_id,omitempty"`
	Day int `json:"day,omitempty"`

	ExercisePlan   Plan   `gorm:"foreignKey:UserID"`
	ExerciseRecord Record `gorm:"foreignKey:UserID"`

	Exercise ExerciseResult `gorm:"-"`
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
func GetUser(userID int) (User, error) {
	u := User{ID: userID}
	return u, db.Preload("ExercisePlan").Preload("ExerciseRecord").Find(&u).Error
}

func (u *User) Update() error {
	if u == nil {
		return fmt.Errorf("user is nil")
	}
	return db.Preload("ExercisePlan").Preload("ExerciseRecord").Save(u).Error
}

type Plan struct {
	ID int `json:"-" gorm:"primaryKey"`
	Model

	UserID int `json:"user_id" gorm:"uniqueIndex"`

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

func (p *Plan) Update() error {
	if p == nil {
		return fmt.Errorf("plan is nil")
	}
	return db.Save(p).Error
}

type Record struct {
	ID int `json:"id" gorm:"primaryKey"`
	Model

	UserID int `json:"user_id" gorm:"uniqueIndex"`

	DailyType string `json:"exercise_type"`
	DailyReps int    `json:"exercise_reps"`
	Calories  int    `json:"burn_calories"`
	Date      string `json:"date"` // ISO 문자열로 직렬화
}

func (r *Record) JSON() ([]byte, error) {
	b, err := json.Marshal(r)
	if err != nil {
		return nil, fmt.Errorf(`json marshal err: %w`, err)
	}
	return b, nil
}

func Init() {
	db.AutoMigrate(&User{}, &Plan{}, &Record{})
}

/*
Map<String, dynamic> toJson() {
return {
'id': id,
'user_id': userId,
'exercise_type': exerciseType,
'exercise_reps': reps,
'burn_calories': calories,
    'date': date.toIso8601String(),               // ISO 문자열로 직렬화
};
}
}
*/
//
