/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import "dotenv/config";
import * as joi from "joi";

interface EnvVars {
  PORT: number;
  NATS_SERVERS: string[];
  DB_URI: string;
}

const envsSchema = joi
  .object({
    PORT: joi.number().required(),
    NATS_SERVERS: joi.array().items(joi.string()).required(),
    DB_URI: joi.string().required(),
  })
  .unknown(true);

const { error, value } = envsSchema.validate({
  ...process.env,
  NATS_SERVERS: process.env.NATS_SERVERS?.split(","),
});

if (error) {
  throw new Error(`config validation error: ${error.message}`);
}

const envVars: EnvVars = value;

export const envs = {
  port: envVars.PORT,
  nats_servers: envVars.NATS_SERVERS,
  db_uri: envVars.DB_URI,
};
