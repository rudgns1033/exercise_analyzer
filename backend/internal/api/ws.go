package api

import (
	"arnold/internal/core"
	"context"
	"encoding/json"
	"github.com/gorilla/websocket"
	"github.com/rs/zerolog/log"
)

type WSData struct {
	ReqID string          `json:"request_id"`
	Type  string          `json:"type"`
	Data  json.RawMessage `json:"data"`
}

var upgrader = websocket.Upgrader{
	HandshakeTimeout:  0,
	ReadBufferSize:    0,
	WriteBufferSize:   0,
	WriteBufferPool:   nil,
	Subprotocols:      nil,
	Error:             nil,
	CheckOrigin:       nil,
	EnableCompression: false,
}

type WSServer struct {
	Conn      *websocket.Conn
	readChan  chan *WSData
	writeChan chan *WSData
}

func NewWSServer(conn *websocket.Conn) *WSServer {
	rc := make(chan *WSData, 64)
	wc := make(chan *WSData, 64)

	return &WSServer{
		Conn:      conn,
		readChan:  rc,
		writeChan: wc,
	}
}

// readData WSData 를 APP 으로부터 받는 함수. (FrameData 등 APP에서 받는 데이터)
func (ws *WSServer) readData() (*WSData, error) {
	wsData := &WSData{}
	err := ws.Conn.ReadJSON(&wsData)
	if err != nil {
		return nil, err
	}
	return wsData, nil
}

// writeData WSData 를 APP 에 보내는 함수. (feedback 등 웹소켓을 통해 APP 에 전달하는 데이터)
func (ws *WSServer) writeData(data *WSData) error {
	err := ws.Conn.WriteJSON(data)
	if err != nil {
		return err
	}
	return nil
}

func (ws *WSServer) readRoutine() (context.Context, context.CancelFunc) {
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		if wd, err := ws.readData(); err != nil {
			log.Error().Err(err).Msg("failed to read data")
		} else {
			ws.readChan <- wd
		}
	}()
	return ctx, cancel
}

func (ws *WSServer) write(reqID string, t string, data interface{}) error {
	b, err := json.Marshal(data)
	if err != nil {
		return err
	}
	wd := &WSData{}
	wd.ReqID = reqID
	wd.Type = t
	wd.Data = b
	ws.writeChan <- wd
	return nil
}

// HandleFrame APP 으로부터 웹소켓을 통해 운동 정보를 받아서 올바르게 운동하였는지 처리하는 함수
func (ws *WSServer) HandleFrame() <-chan struct{} {
	// readRoutine
	ctx, cancel := ws.readRoutine()
	ctx = context.WithoutCancel(ctx)

	go func() {
		for {
			select {
			case <-ctx.Done():
				break
			case data := <-ws.readChan:
				switch data.Type {
				case "frame":
					fd, err := ToFrameData(data.Data)
					if err != nil {
						continue
					}
					exercise := fd.Exercise()
					validate, feedback := exercise.Validate()
					if validate {
						t := "feedback"
						if err := ws.write(data.ReqID, t, feedback); err != nil {
							log.Error().Err(err).Str("type", t).Msg("error writing feedback")
						}
					}

				default:
					cancel()
				}

			default:
				log.Debug().Msg("no data to read")

			}

		}
	}()

	// WriteRoutine
	go func() {
		for {
			select {
			case <-ctx.Done():
				break
			case data := <-ws.writeChan:
				err := ws.writeData(data)
				if err != nil {
					log.Error().Err(err).Msg("failed to write data")
				}
			default:
				log.Debug().Msg("no data to write")
			}
		}
	}()

	return ctx.Done()
}

func ToFrameData(data json.RawMessage) (core.FrameData, error) {
	fd := core.FrameData{}

	if err := json.Unmarshal(data, &fd); err != nil {
		return core.FrameData{}, err
	}
	return fd, nil
}
