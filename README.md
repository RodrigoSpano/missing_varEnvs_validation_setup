# `envs.ts` - Environment Variable Configuration

This file (`envs.ts`) is responsible for managing and validating the environment variables required for this application to run correctly. It ensures that essential configuration parameters are present and adhere to the expected data types.

## Purpose

The primary goals of this file are to:

- **Define the expected environment variables:** It clearly outlines which environment variables the application relies on.
- **Validate environment variable values:** It uses the `joi` library to enforce specific data types and constraints on the environment variables. This helps catch configuration errors early and prevents unexpected behavior.
- **Provide a strongly-typed interface for accessing environment variables:** The `EnvVars` interface and the `envs` constant offer a type-safe way to access the configured environment variables throughout the application.

## How it Works

Let's break down the code step by step:

1.  **Imports:**

    ```typescript
    import * as dotenv from "dotenv/config";
    import * as joi from "joi";
    ```

    - `dotenv/config`: This line imports and immediately executes the configuration function from the `dotenv` library. `dotenv` is used to load environment variables from a `.env` file (if it exists) into the `process.env` object. This allows you to configure the application using external files, which is often preferred for security and deployment flexibility.
    - `joi`: This imports the `joi` library, a powerful schema description language and data validator for JavaScript. It's used here to define the expected structure and types of our environment variables.

2.  **`EnvVars` Interface:**

    ```typescript
    interface EnvVars {
      PORT: number;
      NATS_SERVERS: string[];
      DB_URI: string;
    }
    ```

    - This interface defines the shape of our environment variable object. It specifies the names of the expected variables (`PORT`, `NATS_SERVERS`, `DB_URI`) and their corresponding TypeScript types (`number`, `string[]`, `string`). This provides type safety when accessing these variables later in the code.

3.  **`envsSchema` (Joi Schema):**

    ```typescript
    const envsSchema = joi
      .object({
        PORT: joi.number().required(),
        NATS_SERVERS: joi.array().items(joi.string().required()).required(),
        DB_URI: joi.string().required(),
      })
      .unknown(true);
    ```

    - This section defines a validation schema using `joi`.
      - `joi.object({...})`: Indicates that we are expecting an object.
      - `PORT: joi.number().required()`: Specifies that the `PORT` environment variable must be a number and is required (cannot be undefined).
      - `NATS_SERVERS: joi.array().items(joi.string().required()).required()`: Specifies that `NATS_SERVERS` must be an array. Each item within the array must be a string and is required. This suggests that the application might connect to multiple NATS (a messaging system) servers.
      - `DB_URI: joi.string().required()`: Specifies that `DB_URI` (likely the database connection URI) must be a string and is required.
      - `.unknown(true)`: This allows the `process.env` object to contain other environment variables that are not explicitly defined in this schema without causing a validation error. This is useful if your system has other environment variables set that are not relevant to this specific application.

4.  **Validation Logic:**

    ```typescript
    const { error, value } = envsSchema.validate({
      ...process.env,
      NATS_SERVERS: process.env.NATS_SERVERS?.split(","),
    });

    if (error) {
      throw new Error(`Config validation error: ${error.message}`);
    }
    ```

    - `envsSchema.validate({...})`: This is where the actual validation happens.
      - `...process.env`: It takes all the environment variables currently available in the `process.env` object.
      - `NATS_SERVERS: process.env.NATS_SERVERS?.split(",")`: It specifically takes the `NATS_SERVERS` environment variable from `process.env` and splits it into an array of strings using the comma (`,`) as a delimiter. This allows you to specify multiple NATS server addresses in a single environment variable, separated by commas. The optional chaining (`?.`) ensures that the `split()` method is only called if `process.env.NATS_SERVERS` exists.
    - `const { error, value } = ...`: The `validate()` method returns an object containing two properties: `error` (which will be `null` if validation succeeds, or an error object if it fails) and `value` (the validated and potentially transformed data).
    - `if (error) { throw new Error(...) }`: This checks if an error occurred during validation. If there is an error, it throws a new `Error` with a descriptive message indicating the validation failure. This ensures that the application will not start with invalid configuration.

5.  **Creating the `envs` Constant:**

    ```typescript
    const envs: EnvVars = value as EnvVars;
    ```

    - If the validation is successful, the `value` object (containing the validated environment variables) is cast to the `EnvVars` interface. This creates a strongly-typed `envs` constant that can be used throughout the application to access the validated environment variables.

6.  **Exporting `envs`:**
    ```typescript
    export const envs = {
      port: envs.PORT,
      nats_servers: envs.NATS_SERVERS,
      db_uri: envs.DB_URI,
    };
    ```
    - Finally, the `envs` constant is exported. Notice that the keys are lowercase (`port`, `nats_servers`, `db_uri`) while the original environment variable names in the interface were uppercase (`PORT`, `NATS_SERVERS`, `DB_URI`). This is a common practice to have consistent naming conventions within the application's code.

## How to Use

1.  **Install `dotenv` and `joi`:**
    If you haven't already, you'll need to install these dependencies in your project:

    ```bash
    npm install dotenv joi
    # or
    yarn add dotenv joi
    ```

2.  **Create a `.env` file (optional):**
    In the root of your project, you can create a `.env` file to store your environment variables. For example:

    ```
    PORT=3000
    NATS_SERVERS=nats://localhost:4222,nats://another-server:4222
    DB_URI=mongodb://localhost:27017/mydatabase
    ```

3.  **Import and Use `envs` in your application:**
    In other parts of your application, you can import the `envs` constant to access the configured environment variables with type safety:

    ```typescript
    import { envs } from "./envs";

    console.log(`Server listening on port: ${envs.port}`);
    console.log(`NATS Servers: ${envs.nats_servers}`);
    console.log(`Database URI: ${envs.db_uri}`);

    // Use envs.port, envs.nats_servers, envs.db_uri in your application logic
    ```

## Key Takeaways

- This file promotes **configuration management** by centralizing environment variable handling.
- **Validation** using `joi` ensures the application has the necessary and correctly formatted configuration.
- **Type safety** through the `EnvVars` interface improves code reliability and maintainability.
- The use of `dotenv` allows for **flexible configuration** through `.env` files.
- Splitting the `NATS_SERVERS` string into an array provides support for **multiple server configurations**.

By using this `envs.ts` file, your application becomes more robust and easier to configure across different environments (development, testing, production).

## How to Use

1. **Set your own "variables":**
   You need to go to the envs.ts file created where the validation code is, and upload there your own variables with their types. You can see that there are some examples, just replace them with your own, they would help you understand how it works

### step by step

    - first modify the interface with your variables and types

```ts
interface EnvVars {
  PORT: number;
  NATS_SERVERS: string[];
  DB_URI: string;
}
```

- Then modify the envsSchema with joi types

```ts
  .object({
  PORT: joi.number().required(),
  NATS_SERVERS: joi.array().items(joi.string()).required(),
  DB_URI: joi.string().required(),
  })
  .unknown(true);
```

- if you need to add some extra logic to a specific variables do it as the "NATS_SERVERS" example >>

```ts
const { error, value } = envsSchema.validate({
  ...process.env,
  NATS_SERVERS: process.env.NATS_SERVERS?.split(","),
});
```

- at last but not least, you need to define them in the constant that is going to be exported, this constant is the one you are gonna use to access the variables.

```ts
export const envs = {
  port: envVars.PORT,
  nats_servers: envVars.NATS_SERVERS,
  db_uri: envVars.DB_URI,
};
```

- example of how to call the envs in the app

```ts
  import { envs } from "@config/envs.ts
  console.log(envs.ports)
```
