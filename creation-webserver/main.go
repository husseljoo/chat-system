package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	env "github.com/caitlinelfring/go-env-default"
	"github.com/gin-gonic/gin"
	"github.com/jrallison/go-workers"
	"golang.org/x/exp/rand"
)

var (
	SEQUENCE_GENERATOR_URL = env.GetDefault("SEQUENCE_GENERATOR_URL", "http://localhost:8081")
	QUEUE_CHATS            = env.GetDefault("QUEUE_CHATS", "queue_chats")
	QUEUE_MESSAGES         = env.GetDefault("QUEUE_MESSAGES", "queue_messages")
	SIDEKIQ_REDIS          = env.GetDefault("SIDEKIQ_REDIS", "localhost:6379")
	SIDEKIQ_REDIS_DB       = env.GetDefault("SIDEKIQ_REDIS_DB", "5")
	SIDEKIQ_REDIS_POOL     = env.GetDefault("SIDEKIQ_REDIS_POOL", "10")
)

func InitSidekiq() {
	workers.Configure(map[string]string{
		// location of redis instance
		"server": SIDEKIQ_REDIS,
		// instance of the database
		"database": SIDEKIQ_REDIS_DB,
		// number of connections to keep open with redis
		"pool": SIDEKIQ_REDIS_POOL,
		// unique process id for this instance of workers (for proper recovery of inprogress jobs on crash)
		"process": strconv.Itoa(rand.Intn(10000)),
	})
}

func AddJob(queue string, at time.Time, args ...interface{}) string {
	ts := float64(at.UTC().Unix())
	jid, _ := workers.EnqueueWithOptions(queue, "Add", args, workers.EnqueueOptions{Retry: true, RetryCount: 4, At: ts})
	return jid
}

// applications/:token/chats/
func createChat(c *gin.Context) {
	token := c.Param("token")

	url := fmt.Sprintf("%s/chat?app_token=%s", SEQUENCE_GENERATOR_URL, token)
	chatNumber, err := setTokenRedis(url, "chat_number")
	if err != nil {
		c.JSON(http.StatusInternalServerError, "")
		return
	}
	jsonResponse := map[string]interface{}{
		"chat_number": chatNumber,
	}

	jobId := AddJob(QUEUE_CHATS, time.Now(), token, chatNumber)
	fmt.Printf("Chat creation for application %s added to queue with job_id: %s\n", token, jobId)

	c.IndentedJSON(http.StatusCreated, jsonResponse)
}

// applications/:token/chats/:chat_number/messages
func createMessage(c *gin.Context) {
	token := c.Param("token")
	chatNumber := c.Param("chat_number")

	url := fmt.Sprintf("%s/message?app_token=%s&chat_number=%s", SEQUENCE_GENERATOR_URL, token, chatNumber)
	messageNumber, err := setTokenRedis(url, "message_number")
	if err != nil {
		c.JSON(http.StatusInternalServerError, "")
		return
	}
	jsonResponse := map[string]interface{}{
		"message_number": messageNumber,
	}

	jobId := AddJob(QUEUE_MESSAGES, time.Now(), token, chatNumber, messageNumber)
	fmt.Printf("Message creation for chat number %s of application %s added to queue with job_id: %s\n", chatNumber, token, jobId)

	c.IndentedJSON(http.StatusCreated, jsonResponse)
}

func setTokenRedis(url string, field string) (float64, error) {
	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return 0, fmt.Errorf("error sending request to Redis: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return 0, fmt.Errorf("failed to set token in Redis (status %d): %s", resp.StatusCode, string(body))
	}

	var response map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return 0, fmt.Errorf("error decoding JSON response: %w", err)
	}

	num, ok := response[field]
	if !ok {
		return 0, fmt.Errorf("%s not found in response", field)
	}

	number, ok := num.(float64)
	if !ok {
		return 0, fmt.Errorf("%s conversion error to float64.", field)
	}

	return number, nil
}

func main() {
	InitSidekiq()
	router := gin.Default()
	router.POST("/applications/:token/chats", createChat)
	router.POST("/applications/:token/chats/:chat_number/messages", createMessage)

	router.Run("0.0.0.0:8888")
}
