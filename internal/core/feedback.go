package core

import (
	"encoding/json"
	"fmt"
)

const (
	PUSHUP_ELBOW = "어디 부위의 각도가 "
)

type Feedback struct {
	Correct        bool   `json:"correct"`
	FeedBack       string `json:"feedback"`
	CaloriesBurned int    `json:"calories"`
}

func (f *Feedback) JSON() ([]byte, error) {
	b, err := json.Marshal(f)
	if err != nil {
		return nil, fmt.Errorf(`json marshal err: %w`, err)
	}
	return b, nil
}

type Feedback2 struct {
	VideoID      string `json:"video_id"`
	Frame        int    `json:"frame_num"`
	FrameLength  int    `json:"frame_len"`
	ExerciseName string `json:"name"`
}
