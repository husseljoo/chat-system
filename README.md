### Architecture Overview

![Architecture](./images/chat_system_architecture.png)

#### Components

- **Sidekiq**: Processes background jobs that seamlessly integrates with the Rails application using [ActiveJob](https://edgeguides.rubyonrails.org/active_job_basics.html). (See [sidekiq](https://github.com/sidekiq/sidekiq).)
- **Creation Webserver & Workers**: Process chat/message creation by relying on [go-workers](https://github.com/jrallison/go-workers) who offer Sidekiq compatible background workers in Golang.
- **Sequence Generator**: Api that interfaces with Redis to generate numbers for chats and messages.
  - chat numbers are unique as composite key along with token
  - message numbers are unique as composite key along with token & chat_number
  - allows for creation to be asynchronous and to return the generated numbers immediately to the client.
  - chats and messages will persist eventually
  - used by web servers to omit invalid requests (i.e non-existing token) to avoid database contention
- **Elasticsearch**: Supports full-text search capabilities for message bodies (partial body matching).

#### Design decisions:
- its possible (and probably better) to use the golang api to simply enqueue the jobs to redis and let sidekiq handle all background processing as it has to the same ActiveRecord models as the Rails application. In that case, the golang endpoints will simply enqueue to the same queue that sidekiq is polling from (I already have Active Jobs for CreateChat and CreatMessage), rather than the queues the golang workers are polling from. Changing the `QUEUE_CHATS` and `QUEUE_MESSAGES` env variables will do the job, as long as the golang api passes the needed paramaters in the same order the corresponding ActiveJob is expecting. The golang workers are just to showcase both sides, they are plug and play pretty much.
- application creation will wait until persisted to DB (could be made asynchronous), but decided to guarantee persistence
- service generator and workers use the same Redis service however for larger scale or stricter isolation separate Redis instances could be deployed for each service

### Environment

To spin up the environment run `docker compose up` (you may need to add a `--build` flag).

If you face errors due to building the images in the compose file, you may run this script:
`./build_and_run.sh`

To generate data you can this command after all containers are running:

```
docker run --rm  --network host -v ./scripts:/scripts -w /scripts python:3.12-slim sh -c "pip install -r requirements.txt && python generate_data.py"
```

### Api Documentation

The API documentation is available at http://localhost:8000/api-docs/
