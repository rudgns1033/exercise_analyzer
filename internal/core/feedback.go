package core

const (
	PUSHUP_ELBOW = "어디 부위의 각도가 "
)

type Feedback struct {
	VideoID      string `json:"video_id"`
	Frame        int    `json:"frame_num"`
	FrameLength  int    `json:"frame_len"`
	ExerciseName string `json:"name"`
}
