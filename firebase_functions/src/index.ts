/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import express from "express";
import type {Request, Response} from "express";
import cors from "cors";
import {OpenAI} from "openai";
import {getStorage} from "firebase-admin/storage";
import {initializeApp, cert} from "firebase-admin/app";
import axios from "axios";
import sharp from "sharp";
// import {readFileSync} from "fs";
// import {join} from "path";
import * as serviceAccount from "./service_account.json";
import {defineSecret} from "firebase-functions/params";


// Initialize Firebase Admin with credentials
initializeApp({
  credential: cert(serviceAccount as any),
  storageBucket: "f-food-menu.firebasestorage.app",
});

const app = express();
app.use(cors());
app.use(express.json({limit: "50mb"}));
app.use(express.urlencoded({limit: "50mb", extended: true}));

const openaiSecret = defineSecret("OPENAI_KEY");

// Test endpoints
export const testGet = onRequest(
  {cors: true},
  async (req: Request, res: Response) => {
    try {
      res.json({
        status: "success",
        message: "GET endpoint is working!",
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error("Error in test GET endpoint:", error);
      res.status(500).json({error: "Internal server error"});
    }
  }
);

export const testPost = onRequest(
  {cors: true},
  async (req: Request, res: Response) => {
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
  }
);

// Main endpoints
export const generateImage = onRequest(
  {
    secrets: [openaiSecret],
    memory: "1GiB",
    timeoutSeconds: 120,
    cors: true,
  },
  async (req: Request, res: Response) => {
    try {
      const openai = new OpenAI({apiKey: openaiSecret.value()});
      const {name, ingredients, drinkFlavor} = req.body;

      // Construct prompt based on item type
      let prompt = "";
      if (drinkFlavor) {
        prompt = `Generate a realistic drink image: ${name},` +
          `with characteristics: ${drinkFlavor}`;
      } else {
        const ingredientsText = ingredients.length > 0 ?
          `, with ingredients: ${ingredients.join(", ")}` :
          "";
        prompt = `Generate a realistic food image: ${name}` +
          `${ingredientsText}`;
      }

      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: prompt,
        n: 1,
        size: "1024x1024",
      });

      const imageUrl = response.data[0].url;
      if (!imageUrl) {
        throw new Error("No image URL generated");
      }

      // Download image from DALL-E
      const imageResponse = await axios.get(imageUrl, {
        responseType: "arraybuffer",
      });

      // Resize image to 400x400 using Sharp
      const resizedImageBuffer = await sharp(imageResponse.data)
        .resize(400, 400)
        .toBuffer();

      // Upload to Firebase Storage
      // gsutil cors set cors.json gs://f-food-menu.firebasestorage.app
      const bucket = getStorage().bucket();
      console.log("Bucket name:", bucket.name);
      const datenow = Date.now();
      const fileName = `generated-images/${datenow}.png`;
      const file = bucket.file(fileName);

      await file.save(resizedImageBuffer, {
        metadata: {
          contentType: "image/png",
        },
      });

      // Get public URL
      await file.makePublic();
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
      console.log("publicUrl", publicUrl);
      res.json({
        imageUrl: publicUrl,
        prompt: prompt, // Send back the constructed prompt
      });
    } catch (error) {
      logger.error("Error generating image:", error);
      res.status(500).json({error: "Failed to generate image"});
    }
  }
);

export const extractMenu = onRequest(
  {
    secrets: [openaiSecret],
    memory: "1GiB",
    timeoutSeconds: 120,
    cors: true,
  },
  async (req: Request, res: Response) => {
    try {
      const openai = new OpenAI({apiKey: openaiSecret.value()});
      const {imageBase64} = req.body;
      // eslint-disable-next-line max-len
      const prompt =
      `
      This is a menu, extract all items from the image. 
      If this is a food menu, leave the drinkFlavor field blank. 
      If there's no ingredients showing in the menu, 
      leave the ingredients field blank. 
      For menu in Chinese, leave the ingredients field blank. 
      If the menu is a drink menu, leave the ingredients field blank. 
      And fill the drinkFlavor field in Chinese using 
      brief describition of its flavor and in what situation should 
      we choose this drink and what food it best match with. 
      Output in json format.
      `;
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: [
              // eslint-disable-next-line max-len
              {type: "text", text: prompt},
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
                      drinkFlavor: {
                        type: "string",
                        description: "The flavor of the drink",
                      },
                      // eslint-disable-next-line max-len
                      price: {type: "number", description: "The price of the item in USD"},
                    },
                    required: ["name"],
                  },
                },
              },
              additionalProperties: false,
            },
          },
        },
        max_tokens: 2000,
      });

      const temp = response.choices[0].message.content;
      logger.info("response", temp);
      res.json({menuItems: JSON.parse(temp || "[]")});
    } catch (error) {
      logger.error("Error extracting menu:", error);
      res.status(500).json({error: "Failed to extract menu items"});
    }
  }
);
