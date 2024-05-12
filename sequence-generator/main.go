package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/go-redis/redis/v8"
)

var redisClient *redis.Client

func init() {
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}
	redisClient = redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: "", // no password set
		DB:       0,  // default DB
	})

	ctx := context.Background()
	pong, err := redisClient.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	log.Printf("Connected to Redis: %s", pong)
}

func messageHandler(w http.ResponseWriter, r *http.Request) {
	appToken := r.FormValue("app_token")
	chatNumber := r.FormValue("chat_number")

	if appToken == "" || chatNumber == "" {
		http.Error(w, "app_token and chat_number must be provided", http.StatusBadRequest)
		return
	}

	ctx := context.Background()
	key := fmt.Sprintf("%s:%s", appToken, chatNumber)

	messageNumber := int64(0)
	if r.Method == http.MethodPost {
		exists, err := redisClient.Exists(ctx, key).Result()
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to check if key exists: %v", err), http.StatusInternalServerError)
			return
		}

		if exists == 0 {
			http.Error(w, "Key does not exist", http.StatusNotFound)
			return
		}
		newVal, err := redisClient.Incr(ctx, key).Result()
		messageNumber = newVal
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to increment message count: %v", err), http.StatusInternalServerError)
			return
		}
	} else if r.Method == http.MethodGet {
		newVal, err := redisClient.Get(ctx, key).Result()
		messageNumber, _ = strconv.ParseInt(newVal, 10, 64)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get message count: %v", err), http.StatusInternalServerError)
			return
		}
	} else if r.Method == http.MethodPut {
		first_instance, err := redisClient.SetNX(ctx, key, 0, 0).Result()
		fmt.Printf("first_instance: %s=%t\n", key, first_instance)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to set chat count to zero: %v", err), http.StatusInternalServerError)
			return
		}
		response := map[string]bool{"first_inctance": first_instance}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, fmt.Sprintf("an not marshal json response %v.", err), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)

	} else if r.Method == http.MethodDelete {
		res, err := redisClient.Del(ctx, key).Result()
		fmt.Printf("res: %s=%d\n", key, res)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to delete key: %v", err), http.StatusInternalServerError)
			return
		}
		deleted := res == 1
		response := map[string]bool{"deleted": deleted}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, fmt.Sprintf("an not marshal json response %v.", err), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)
	}

	if r.Method == http.MethodPost || r.Method == http.MethodGet {
		response := map[string]int64{"message_number": messageNumber}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, fmt.Sprintf("an not marshal json response %v.", err), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)
	}
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
}

func chatHandler(w http.ResponseWriter, r *http.Request) {
	appToken := r.FormValue("app_token")

	if appToken == "" {
		http.Error(w, "app_token must be provided", http.StatusBadRequest)
		return
	}

	ctx := context.Background()
	key := appToken

	chatNumber := int64(0)
	if r.Method == http.MethodPost {
		exists, err := redisClient.Exists(ctx, key).Result()
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to check if key exists: %v", err), http.StatusInternalServerError)
			return
		}

		if exists == 0 {
			http.Error(w, "Key does not exist", http.StatusNotFound)
			return
		}

		// Increment the value of the key
		newVal, err := redisClient.Incr(ctx, key).Result()
		chatNumber = newVal
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to increment chat count: %v", err), http.StatusInternalServerError)
			return
		}
	} else if r.Method == http.MethodGet {
		newVal, err := redisClient.Get(ctx, key).Result()
		chatNumber, _ = strconv.ParseInt(newVal, 10, 64)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get value for key %s: %v", key, err), http.StatusInternalServerError)
			return
		}
	} else if r.Method == http.MethodPut {
		first_instance, err := redisClient.SetNX(ctx, key, 0, 0).Result()
		fmt.Printf("first_instance: %s=%t\n", key, first_instance)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to set chat count to zero: %v", err), http.StatusInternalServerError)
			return
		}
		response := map[string]bool{"first_inctance": first_instance}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, fmt.Sprintf("an not marshal json response %v.", err), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)

	} else if r.Method == http.MethodDelete {
		res, err := redisClient.Del(ctx, key).Result()
		fmt.Printf("res: %s=%d\n", key, res)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to delete key: %v", err), http.StatusInternalServerError)
			return
		}
		deleted := res == 1
		response := map[string]bool{"deleted": deleted}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, fmt.Sprintf("an not marshal json response %v.", err), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)
	}

	if r.Method == http.MethodPost || r.Method == http.MethodGet {
		response := map[string]int64{"chat_number": chatNumber}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, fmt.Sprintf("an not marshal json response %v.", err), http.StatusInternalServerError)
			return
		}
		w.Write(jsonResponse)
	}

	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
}

func main() {
	port := 8081

	http.HandleFunc("/chat", chatHandler)
	http.HandleFunc("/message", messageHandler)

	log.Printf("Server listening on port %d", port)
	log.Fatal(http.ListenAndServe(":"+strconv.Itoa(port), nil))
}
