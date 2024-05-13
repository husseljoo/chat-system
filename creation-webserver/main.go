package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-sql-driver/mysql"
)

const (
	SEQUENCE_GENERATOR_URL = "http://localhost:8081"
)

var dbConfig = mysql.Config{
	User:   "root",
	Passwd: "root",
	Net:    "tcp",
	Addr:   "localhost:3311",
	DBName: "chat_system_dev",
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
		return 0, fmt.Errorf("chat_number not found in response")
	}

	number, ok := num.(float64)
	if !ok {
		return 0, fmt.Errorf("chat_number conversion error to float64.")
	}

	return number, nil
}

func main() {
	router := gin.Default()
	router.POST("/applications/:token/chats", createChat)
	router.POST("/applications/:token/chats/:chat_number/messages", createMessage)

	router.Run("localhost:8888")
}
