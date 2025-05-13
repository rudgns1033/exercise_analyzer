package core

const (
	JointA = iota // 머리
	JointB
	JointC
)

type LandMarks []Joint

func (l LandMarks) Get(idx int) Joint {
	if len(l) > idx {
		return l[idx]
	}
	return Joint{}
}

type Joint struct {
	Type string  `json:"type"`
	X    float64 `json:"x"`
	Y    float32 `json:"y"`
	Z    float32 `json:"z"`
}

type Angle struct {
	Name   string
	Radius float64
	Joints []Joint
	Check  func(int) bool
}

func calcAngle(joints ...Joint) float64 {
	if joints == nil {
		return -1
	}
	//for _, j := range joints {
	//
	//}
	return 0
}

// 운동 종류별로 계산로직이 달라지므로 아래는 사용하기 어려움

//func newWrist(joints ...Joint) Angle {
//	return Angle{
//		Name:   "Wrist",
//		Radius: calcAngle(joints...),
//		Joints: joints,
//		Check:  wristCheck,
//	}
//}
//
//func newArm(joints ...Joint) Angle {
//	return Angle{
//		Name:   "Arm",
//		Radius: calcAngle(joints...),
//		Joints: joints,
//		Check:  wristCheck,
//	}
//}
