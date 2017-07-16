curl --request POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header 'authorization: Bearer ${mail_key}' \
  --header 'content-type: application/json' \
  --data '{"personalizations":[{"to":[{"email":"${email}"}],"subject":"Your ISO is Ready"}],"from":{"email":"xeon.harsh@gmail.com","name":"Meilix Generator"},"reply_to":{"email":"xeon.harsh@gmail.com","name":"Meilix Generator"},"subject":"Your ISO is ready","content":[{"type":"text/html","value":"<html><p>Hi,<br>Your ISO is ready <br><br>Thank You,<br>Meilix Generator Team</p></html>"}]}'

