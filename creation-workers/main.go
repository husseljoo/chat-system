package main

import (
	"database/sql"
	"fmt"
	"log"
	"strconv"

	env "github.com/caitlinelfring/go-env-default"
	"github.com/go-sql-driver/mysql"
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
	CHAT_CONCURRENCY       = env.GetIntDefault("CHAT_CONCURRENCY", 10)
	MESSAGE_CONCURRENCY    = env.GetIntDefault("MESSAGE_CONCURRENCY", 10)
)

var dbConfig = mysql.Config{
	User:   env.GetDefault("DB_USERNAME", "root"),
	Passwd: env.GetDefault("DB_PASSWORD", "root"),
	Net:    "tcp",
	Addr:   fmt.Sprintf("%s:%s", env.GetDefault("DB_HOST", "localhost"), env.GetDefault("DB_PORT", "3311")),
	DBName: env.GetDefault("DB_NAME", "chat_system_dev"),
}

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

func CreateChatJob(message *workers.Msg) {
	args, _ := message.Args().Array()
	fmt.Printf("CreateChatJob: Processing job %s, args: %v\n", message.Jid(), args)
	token := args[0]
	chatNumber := args[1]

	db, err := sql.Open("mysql", dbConfig.FormatDSN())
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	query := "INSERT INTO chats (token, number, created_at, updated_at) VALUES (?, ?, NOW(), NOW())"
	_, err = db.Exec(query, token, chatNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Job %s: Created chat number %s for application %s\n", message.Jid(), chatNumber, token)

	return
}

func CreateMessageJob(message *workers.Msg) {
	args, _ := message.Args().Array()
	fmt.Printf("CreateChatJob: Processing job %s, args: %v\n", message.Jid(), args)
	token := args[0]
	chatNumber := args[1]
	messageNumber := args[2]
	body := args[3]

	db, err := sql.Open("mysql", dbConfig.FormatDSN())
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	query := `
        INSERT INTO messages (chat_id, number, body, created_at, updated_at)
        SELECT c.id, ?, ?, NOW(), NOW()
        FROM chats c
        WHERE c.token = ? AND c.number = ?;
        `
	_, err = db.Exec(query, messageNumber, body, token, chatNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Job %s: Created message number %s in chat number %s of application %s\n", message.Jid(), messageNumber, chatNumber, token)

	return
}

func main() {
	InitSidekiq()
	workers.Process(QUEUE_CHATS, CreateChatJob, CHAT_CONCURRENCY)
	workers.Process(QUEUE_MESSAGES, CreateMessageJob, MESSAGE_CONCURRENCY)

	workers.Run()
}
