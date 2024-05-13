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

func createChat(c *gin.Context) {
	token := c.Param("token")

	url := fmt.Sprintf("%s/chat?app_token=%s", SEQUENCE_GENERATOR_URL, token)
	chatNumber, err := setTokenRedis(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, "")
		return
	}
	jsonResponse := map[string]interface{}{
		"chat_number": chatNumber,
	}

	c.IndentedJSON(http.StatusCreated, jsonResponse)
}
func setTokenRedis(url string) (float64, error) {
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

	num, ok := response["chat_number"]
	if !ok {
		return 0, fmt.Errorf("chat_number not found in response")
	}

	chatNumber, ok := num.(float64)
	if !ok {
		return 0, fmt.Errorf("chat_number conversion error to float64.")
	}

	return chatNumber, nil
}

func main() {
	router := gin.Default()
	router.POST("/applications/:token/chats", createChat)
	// router.POST("/applications/:token/chats/:chat_number/", createMessage)

	router.Run("localhost:8888")
}
