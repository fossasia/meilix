#! /usr/bin/env python3
import http.client
import os
conn = http.client.HTTPSConnection("api.sendgrid.com")
print (os.environ["email"])
payload = "{\"personalizations\":[{\"to\":[{\"email\":\"" + os.environ["email"] + "\"}],\"subject\":\"Your ISO is Ready\"}],\"from\":{\"email\":\"xeon.harsh@gmail.com\",\"name\":\"Meilix Generator\"},\"reply_to\":{\"email\":\"xeon.harsh@gmail.com\",\"name\":\"Meilix Generator\"},\"subject\":\"Your ISO is ready\",\"content\":[{\"type\":\"text/html\",\"value\":\"<html><p>Hi,<br>Your ISO is ready <br><br>Thank You,<br>Meilix Generator Team</p></html>\"}]}"
print (type(payload))

headers = {
    'authorization': "Bearer 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",
    'content-type': "application/json"
    }

conn.request("POST", "/v3/mail/send", payload, headers)

res = conn.getresponse()
data = res.read()

print(data.decode("utf-8"))
