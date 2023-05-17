const express = require('express')
const axios = require('axios')
const { MongoClient, ServerApiVersion } = require('mongodb');
require('dotenv').config();

const dbName = process.env.MONGODB_DB;
const helpCollectionName = process.env.MONGODB_HELP_COLLECTION;
const slackWebhookUrl = process.env.SLACK_WEBHOOK_URL;
const PORT = process.env.PORT || 3030;

const uri = "mongodb+srv://grama_check_admin:1cWV0fu2JasChRh0@gramacheckcluster.used77d.mongodb.net/?retryWrites=true&w=majority";
const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

let collection; 

async function run() {
  try {
    await client.connect();
    const db = client.db(dbName);
    collection = db.collection(helpCollectionName);
    console.log("Successfully connected to MongoDB " + dbName + " database!");
  } catch (err) {
    console.log("ERROR: ", err);
  }
}
run().catch(console.dir);

const app = express()
app.use(express.json())

// const checkCollection = (req, res, next) => {
//   if (!collection) {
//     return res.status(500).send('MongoDB collection is not available');
//   }
//   next();
// };
app.post('/', async (req, res) => {
  const { body } = req

  if (body.challenge) {
    res.status(200).send({ challenge: body.challenge})
  } else {
    const event = body.event
    if (event && event.type === 'app_mention') {
      const matches = event.text.match(/requester: <mailto:(.*?)\|.*?>[\n\r]+request: (.*?)[\n\r]+reply: (.*)/s);
      const requesterEmail = matches[1].replace('mailto:', '');
      const requestMessage = matches[2];
      const replyMessage = matches[3];

      console.log('Requester:', requesterEmail);
      console.log('Request:', requestMessage);
      console.log('Reply:', replyMessage);

      const filter = { public_user_email: requesterEmail, msg: requestMessage };
      const result = await collection.find(filter).toArray();

      console.log('Result:', result)

      if (result.length == 0) {
        res.status(400).send('No matching request found');
      } else if (result.length > 1) {
        res.status(400).send('Multiple matching request found. Please check the requester email and request msg again');
      } else {
        const updateDoc = {
          $set: {
            status: 'CLOSED',
            reply: replyMessage
          }
        };
        const result = await collection.updateOne(filter, updateDoc);
        if (result.matchedCount > 0) {
          console.log(`Successfully updated the document with _id: ${result.matchedCount}`);
          res.status(200).send('Successfully updated the request');
        } else {
          console.error('Failed to update the document');
          res.status(500).send('Failed to update the request');
        }
      }
    }
  } 
})
const server = app.listen(PORT,  async () => {
  console.log(`Server is running on port ${PORT}`)

  app.post('/help/put_slack_msg', (req, res) => {
    const { body } = req
    let public_user_email = body.public_user_email
    let msg = body.msg
    let gramasevaka_area = body.gramasevaka_area
    const status = "OPENED"
    const reply = "none"

    const document = {
      public_user_email: public_user_email,
      msg: msg,
      gramasevaka_area: gramasevaka_area,
      status: "OPENED",
      reply: "none"
    };
    collection.insertOne(document, (err, result) => {
      if (err) {
        console.error('Error inserting document:', err);
        res.status(500).send('Error inserting document');
      } else {
        console.log('Document inserted successfully:', result.insertedId);
      }
    });
    axios.post(slackWebhookUrl, {
          "blocks": [
            {
              "type": "section",
              "text": {
                "type": "plain_text",
                "text": `public_user_email: ${public_user_email}`,
                "emoji": false
              }
            },
            {
              "type": "section",
              "text": {
                "type": "plain_text",
                "text": `msg: ${msg}`,
                "emoji": false
              }
            },
            {
              "type": "section",
              "text": {
                "type": "plain_text",
                "text": `status: ${status}`,
                "emoji": false
              }
            },
            {
              "type": "section",
              "text": {
                "type": "plain_text",
                "text": `gramasevaka_area: ${gramasevaka_area}`,
                "emoji": false
              }
            },
            {
              "type": "section",
              "text": {
                "type": "plain_text",
                "text": `reply: ${reply}`,
                "emoji": false
              }
            }
          ]
        }).then((result) => {
            res.status(200).send("Successfully sent the message to Slacks")
          }).catch((err) => {
            console.log("ERROR: ",  err)
            res.status(500).send("Failed to send the message to Slack")
          });
  })

})

// Handle server stop event
server.on('close', async () => {
  // Close the MongoDB client connection
  await client.close();
  console.log('MongoDB connection closed');
});

// Gracefully handle server shutdown
process.on('SIGINT', () => {
  server.close(() => {
    console.log('Express server stopped');
    process.exit(0);
  });
});