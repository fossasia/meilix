#! /usr/bin/env python3
import http.client
import os
import datetime

conn = http.client.HTTPSConnection("api.sendgrid.com")

date = datetime.datetime.now().strftime('%Y%m%d')
url = "https://github.com/xeon-zolt/meilix/releases/download/"+os.environ["TRAVIS_TAG"]+"/meilix-i386-custom.iso"

print (os.environ["email"])
payload = "{\"personalizations\":[{\"to\":[{\"email\":\"" + os.environ["email"] + "\"}],\"subject\":\"Your ISO is Ready\"}],\"from\":{\"email\":\"xeon.harsh@gmail.com\",\"name\":\"Meilix Generator\"},\"reply_to\":{\"email\":\"xeon.harsh@gmail.com\",\"name\":\"Meilix Generator\"},\"subject\":\"Your ISO is ready\",\"content\":[{\"type\":\"text/html\",\"value\":\"<html><p>Hi,<br>Your ISO is ready<br>URL : "+url+"<br><br>Thank You,<br>Meilix Generator Team</p></html>\"}]}"

print (type(payload))

authorization = "Bearer " + os.environ["mail_api_key"] 

headers = {
    'authorization': authorization,
    'content-type': "application/json"
    }

conn.request("POST", "/v3/mail/send", payload, headers)

res = conn.getresponse()
data = res.read()

print(data.decode("utf-8"))
