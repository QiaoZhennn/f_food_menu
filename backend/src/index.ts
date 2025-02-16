import * as functions from 'firebase-functions';
import express, { Request, Response } from 'express';
import cors from 'cors';
import OpenAI from 'openai';

const app = express();
app.use(cors());
app.use(express.json());

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

interface GenerateImageRequest {
  prompt: string;
}

interface ExtractTextRequest {
  imageBase64: string;
}

app.post('/generate-image', async (req: Request<{}, {}, GenerateImageRequest>, res: Response) => {
  try {
    const { prompt } = req.body;
    const response = await openai.images.generate({
      model: "dall-e-3",
      prompt: prompt,
      n: 1,
      size: "1024x1024",
    });
    res.json({ imageUrl: response.data[0].url });
  } catch (error) {
    console.error('Error generating image:', error);
    res.status(500).json({ error: 'Failed to generate image' });
  }
});

app.post('/extract-menu', async (req: Request<{}, {}, ExtractTextRequest>, res: Response) => {
  try {
    const { imageBase64 } = req.body;
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: "This is a food menu, extract all food items from the image. Output in json format. Use your best judgement to determine the name of the item, the ingredients and the price." },
            { 
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`
              }
            }
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
                    name: { type: "string", description: "The name of the item" },
                    ingredients: { 
                      type: "array", 
                      items: { type: "string" },
                      description: "A list of ingredient of this food"
                    },
                    price: { type: "number", description: "The price of the item in USD" }
                  },
                  required: ["name", "price"]
                }
              }
            },
            additionalProperties: false
          }
        }
      },
      store: true,
      max_tokens: 1000,
    });

    const temp = response.choices[0].message.content;
    console.log('response', temp);
    res.json({ 
      menuItems: JSON.parse(temp || '[]')
    });
  } catch (error) {
    console.error('Error extracting menu:', error);
    res.status(500).json({ error: 'Failed to extract menu items' });
  }
});

export const api = functions.https.onRequest(app); 