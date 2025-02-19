import * as dotenv from "dotenv";
dotenv.config();
/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import express from "express";
import type {Request, Response} from "express";
import cors from "cors";
import {OpenAI} from "openai";

const openaiKey:string = process.env.NODE_ENV === "development" ?
  process.env.OPENAI_KEY! :
  defineSecret("OPENAI_KEY").value()!;

const app = express();
app.use(cors());
app.use(express.json());

// const openaiRouter = express.Router();
app.get("/testget", async (req: Request, res: Response) => {
  try {
    console.log("openaiKey", openaiKey);
    res.json({
      status: "success",
      message: "GET endpoint is working!",
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error("Error in test GET endpoint:", error);
    res.status(500).json({error: "Internal server error"});
  }
});

app.post("/testpost", async (req: Request, res: Response) => {
  try {
    res.json({
      status: "success",
      message: "POST endpoint is working!",
      receivedBody: req.body || {},
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error("Error in test POST endpoint:", error);
    res.status(500).json({error: "Internal server error"});
  }
});

app.post("/generate-image", async (req: Request, res: Response) => {
  try {
    const openai = new OpenAI({apiKey: openaiKey});
    const {prompt} = req.body;
    const response = await openai.images.generate({
      model: "dall-e-3",
      prompt: prompt,
      n: 1,
      size: "1024x1024",
    });
    res.json({imageUrl: response.data[0].url});
  } catch (error) {
    logger.error("Error generating image:", error);
    res.status(500).json({error: "Failed to generate image"});
  }
});

app.post("/extract-menu", async (req: Request, res: Response) => {
  try {
    const openai = new OpenAI({apiKey: openaiKey});
    const {imageBase64} = req.body;
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            // eslint-disable-next-line max-len
            {type: "text", text: "This is a food menu, extract all food items from the image. Output in json format."},
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
              },
            },
          ],
        },
      ],
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "items_schema",
          schema: {
            type: "object",
            properties: {
              items: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    // eslint-disable-next-line max-len
                    name: {type: "string", description: "The name of the item"},
                    ingredients: {
                      type: "array",
                      items: {type: "string"},
                      description: "A list of ingredient of this food",
                    },
                    // eslint-disable-next-line max-len
                    price: {type: "number", description: "The price of the item in USD"},
                  },
                  required: ["name", "price"],
                },
              },
            },
            additionalProperties: false,
          },
        },
      },
      max_tokens: 1000,
    });

    const temp = response.choices[0].message.content;
    logger.info("response", temp);
    res.json({menuItems: JSON.parse(temp || "[]")});
  } catch (error) {
    console.log("error", error);
    logger.error("Error extracting menu:", error);
    res.status(500).json({error: "Failed to extract menu items"});
  }
});

// app.use("/", openaiRouter);
// app.listen(3000, () => {
//   logger.info("Server is running on port 3000");
// });
// For local development
if (process.env.NODE_ENV === "development") {
  const PORT = 3000;
  app.listen(PORT, () => {
    logger.info(`Server is running on http://localhost:${PORT}`);
  });
}

export const api = onRequest({secrets: [openaiKey]}, app);
