package core

const (
	PUSHUP = "pushup"
	PULLUP = "pullup"
)

type Exercise interface {
	WristAngle() Angle
	wristCheck(condition int) bool
	String() string
	Validate() (bool, *Feedback)
}

type PushUp struct {
	LandMarks
}

func (p *PushUp) String() string {
	return PUSHUP
}

func (p *PushUp) Validate() (bool, *Feedback) {
	return false, &Feedback{
		Correct:        false,
		FeedBack:       p.String(),
		CaloriesBurned: 1,
	}
}

type PullUp struct {
	LandMarks
}

func (p *PullUp) Validate() (bool, *Feedback) {
	return true, nil
}

func (p *PullUp) String() string {
	return PULLUP
}

func (p *PushUp) wristCheck(condition int) bool {
	return true
}

func (p *PushUp) armCheck(condition int) bool {
	return true
}

func (p *PushUp) newWrist(joints ...Joint) Angle {
	return Angle{
		Name:   "Wrist",
		Radius: calcAngle(joints...),
		Joints: joints,
		Check:  p.wristCheck,
	}
}

func (p *PushUp) newArm(joints ...Joint) Angle {
	return Angle{
		Name:   "Arm",
		Radius: calcAngle(joints...),
		Joints: joints,
		Check:  p.armCheck,
	}
}

func (p *PushUp) WristAngle() Angle {
	return p.newWrist(p.LandMarks.Get(JointA), p.LandMarks.Get(JointB), p.LandMarks.Get(JointC))
}

type FrameData struct {
	ID           string    `json:"id"`
	Frame        int       `json:"frame_num"`
	FrameLength  int       `json:"frame_len"`
	ExerciseName string    `json:"name"`
	UserID       int       `json:"user_id"`
	LandMarks    LandMarks `json:"joint_data"`
}

func (f *FrameData) Exercise() Exercise {
	return newExercise(f.ExerciseName, f.LandMarks)
}

func newExercise(exerciseName string, landmarks LandMarks) Exercise {
	switch exerciseName {
	case PUSHUP:
		return &PushUp{
			LandMarks: landmarks,
		}
	case PULLUP:
		return &PushUp{
			LandMarks: landmarks,
		}
	}
	return nil
}

func ValidateExercise(e Exercise) (bool, error) {
	if e == nil {
		return false, nil
	}

	exerciseName := e.String()

	switch exerciseName {
	case PUSHUP:
		e.Validate()

	}

	wrist := e.WristAngle()
	wrist.Check(1)

	return true, nil
}
