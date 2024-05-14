import requests
from faker import Faker

faker = Faker()

app_url = "http://localhost:3000/applications"

apps_num = 5
chats_num = 10
messages_num = 100

tokens = []
for _ in range(apps_num):
    random_name = faker.name().split()[0]
    data = {"name": f"{random_name}App"}
    response = requests.post(app_url, json=data)

    if response.status_code == 200 or response.status_code == 201:
        token = response.json()["token"]
        tokens.append(token)
        # print(f"request successful: {random_name}")
    # else:
    #     print(f"request failed: {random_name}")
# print(tokens)

message_composite = []
for token in tokens:
    for _ in range(chats_num):
        data = {"token": token}
        url = f"{app_url}/{token}/chats/"
        response = requests.post(url, json=data)
        if response.status_code == 200 or response.status_code == 201:
            number = response.json()["chat_number"]
            message_composite.append((token, number))
            # print(f"request successful chat_number:: {number}")
        # else:
        #     print(f"request failed")

for token, chat_number in message_composite:
    body = faker.paragraph(nb_sentences=3)
    data = {"token": token, "chat_number": chat_number, "body": body}
    for _ in range(messages_num):
        body = faker.paragraph(nb_sentences=3)
        data["body"] = body
        url = f"{app_url}/{token}/chats/{chat_number}/messages"
        response = requests.post(url, json=data)
        if response.status_code == 200 or response.status_code == 201:
            number = response.json()["message_number"]
            # print(f"request successful chat_number:: {number}")
        # else:
            # print(f"request failed")
