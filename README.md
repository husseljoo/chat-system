### Architecture
![Architecture](./images/chat_system_architecture.png)

### Environment
To spin up the environment run `docker compose up` (you may need to add a `--build` flag).
To populate the data you can run the following command:
`docker run --rm python `

If you face errors due to building the images in the compose file, you may run this script:
`./build_and_run.sh`

To generate data you can this command after all containers are running:
`docker run --rm -v ./generate_data.py:/script -w /script python:3 python generate_data.py`

### Api Documentation
The API documentation is available at http://localhost:8000/api-docs/
